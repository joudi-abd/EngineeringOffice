import { Injectable, inject, signal } from '@angular/core';
import { LanguageService } from './language.service';
import { Lang } from './site-content';

const STORE_KEY = 'ufuq-translations-v1';
const STORE_LIMIT = 600;
const ENDPOINT = 'https://api.mymemory.translated.net/get';
const CHUNK = 440;
const PARALLEL = 5;
const RETRY_AFTER = 5 * 60 * 1000;
const COOLDOWN = 15 * 60 * 1000;

const ARABIC = /[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]/g;
const LATIN = /[A-Za-z]/g;

/**
 * Translates text that comes from the API (the backend stores one language only).
 * Arabic content is shown in English when the site is English, and English content is
 * shown in Arabic when the site is Arabic. Results are cached in memory and in
 * localStorage, so every string is requested at most once per browser.
 */
@Injectable({ providedIn: 'root' })
export class Translator {
  private readonly i18n = inject(LanguageService);

  private readonly cache = new Map<string, string>(this.restore());
  private readonly queue = new Map<string, { target: Lang; text: string }>();
  private readonly failed = new Map<string, number>();
  private readonly version = signal(0);
  private timer: ReturnType<typeof setTimeout> | undefined;
  private running = 0;
  private pausedUntil = 0;

  /** Number of strings currently waiting for a translation. */
  readonly pending = signal(0);

  /**
   * Returns the translation when it is cached, otherwise the original text while the
   * translation is fetched in the background. Reading it inside a computed makes that
   * computed refresh as soon as the translation arrives.
   */
  text(value: string | null | undefined): string {
    this.version();
    const original = value ?? '';
    const target = this.i18n.lang();
    if (!needsTranslation(original, target)) return original;
    const place = lookupPlaces(original);
    if (place) return place;
    const key = keyOf(target, original);
    const hit = this.cache.get(key);
    if (hit !== undefined) return hit;
    this.enqueue(key, target, original);
    return original;
  }

  /** People's names are transliterated locally (never translated by meaning). */
  name(value: string | null | undefined): string {
    const original = value ?? '';
    if (this.i18n.lang() !== 'en') return original;
    return transliterateName(original);
  }

  /** Same as {@link text} but keeps `null` as `null`. */
  maybe(value: string | null | undefined): string | null {
    if (value == null) return null;
    return this.text(value);
  }

  private enqueue(key: string, target: Lang, text: string): void {
    if (this.queue.has(key)) return;
    const failedAt = this.failed.get(key);
    if (failedAt && Date.now() - failedAt < RETRY_AFTER) return;
    // Never write to a signal here: this runs while a computed is being evaluated.
    this.queue.set(key, { target, text });
    if (this.timer === undefined) this.timer = setTimeout(() => this.flush(), 40);
  }

  private flush(): void {
    this.timer = undefined;
    if (Date.now() < this.pausedUntil) {
      this.timer = setTimeout(() => this.flush(), this.pausedUntil - Date.now());
      return;
    }
    this.pending.set(this.queue.size + this.running);
    while (this.running < PARALLEL && this.queue.size) {
      const [key, job] = this.queue.entries().next().value as [string, { target: Lang; text: string }];
      this.queue.delete(key);
      this.running += 1;
      void this.translate(job.text, job.target)
        .then((result) => {
          if (result === null) {
            this.failed.set(key, Date.now());
          } else {
            this.cache.set(key, result);
            this.version.update((value) => value + 1);
            this.persist();
          }
        })
        .finally(() => {
          this.running -= 1;
          this.pending.set(this.queue.size + this.running);
          if (this.queue.size) this.flush();
        });
    }
  }

  private async translate(text: string, target: Lang): Promise<string | null> {
    const source: Lang = target === 'en' ? 'ar' : 'en';
    const parts = text.split(/(\n+)/);
    const out: string[] = [];
    for (const part of parts) {
      if (!part.trim() || /^\n+$/.test(part)) {
        out.push(part);
        continue;
      }
      const lead = part.match(/^\s*/)?.[0] ?? '';
      const trail = part.match(/\s*$/)?.[0] ?? '';
      const pieces: string[] = [];
      for (const chunk of chunks(part.trim())) {
        const done = await this.request(chunk, source, target);
        if (done === null) return null;
        pieces.push(done);
      }
      out.push(lead + pieces.join(' ') + trail);
    }
    return out.join('');
  }

  private async request(chunk: string, source: Lang, target: Lang): Promise<string | null> {
    if (!needsTranslation(chunk, target)) return chunk;
    try {
      const url = `${ENDPOINT}?q=${encodeURIComponent(chunk)}&langpair=${source}|${target}`;
      const response = await fetch(url, { signal: AbortSignal.timeout(20000) });
      if (response.status === 429) {
        this.pausedUntil = Date.now() + COOLDOWN;
        return null;
      }
      if (!response.ok) return null;
      const body = (await response.json()) as {
        responseStatus?: number | string;
        quotaFinished?: boolean;
        responseData?: { translatedText?: string };
        matches?: { translation?: string; match?: number }[];
      };
      if (body.quotaFinished) {
        this.pausedUntil = Date.now() + COOLDOWN;
        return null;
      }
      if (Number(body.responseStatus) !== 200) return null;
      let translated = body.responseData?.translatedText;
      if (!translated || /MYMEMORY WARNING|QUERY LENGTH LIMIT/i.test(translated)) return null;
      if (needsTranslation(translated, target)) {
        // Single words often come back untouched; the alternative matches usually hold the real translation.
        const alternative = (body.matches ?? [])
          .filter((item) => item.translation && !needsTranslation(item.translation, target) && !/MYMEMORY/i.test(item.translation))
          .sort((a, b) => Number(b.match ?? 0) - Number(a.match ?? 0))[0];
        if (!alternative?.translation) return null;
        translated = alternative.translation;
        if (translated === translated.toUpperCase() && chunk.length < 40) translated = translated.charAt(0) + translated.slice(1).toLowerCase();
      }
      return tidy(translated, chunk);
    } catch {
      return null;
    }
  }

  private restore(): [string, string][] {
    try {
      const raw = localStorage.getItem(STORE_KEY);
      const parsed = raw ? (JSON.parse(raw) as unknown) : [];
      return Array.isArray(parsed) ? (parsed as [string, string][]).filter((entry) => Array.isArray(entry) && entry.length === 2) : [];
    } catch {
      return [];
    }
  }

  private persist(): void {
    try {
      const entries = [...this.cache.entries()].slice(-STORE_LIMIT);
      localStorage.setItem(STORE_KEY, JSON.stringify(entries));
    } catch {
      /* storage may be full or unavailable */
    }
  }
}

function keyOf(target: Lang, text: string): string {
  return `${target}\u0001${text}`;
}

export function needsTranslation(value: string, target: Lang): boolean {
  const text = value.trim();
  if (text.length < 2) return false;
  if (/^(https?:\/\/|www\.)/i.test(text) || /\S+@\S+\.\S+/.test(text)) return false;
  if (!/\p{L}/u.test(text)) return false;
  const arabic = (text.match(ARABIC) ?? []).length;
  const latin = (text.match(LATIN) ?? []).length;
  // Only Arabic -> English: Latin text on the Arabic site is usually a name or a brand.
  return target === 'en' && arabic > 0 && arabic * 2 >= latin;
}

const NAMES: Record<string, string> = {
  محمد: 'Mohammed', احمد: 'Ahmad', علي: 'Ali', عمر: 'Omar', خالد: 'Khaled', يوسف: 'Yousef', ابراهيم: 'Ibrahim',
  حسن: 'Hassan', حسين: 'Hussein', مصطفى: 'Mustafa', محمود: 'Mahmoud', عثمان: 'Othman', سامر: 'Samer', سامي: 'Sami',
  فادي: 'Fadi', وليد: 'Walid', طارق: 'Tarek', زياد: 'Ziad', ياسر: 'Yasser', ماهر: 'Maher', رامي: 'Rami', باسل: 'Basel',
  بشار: 'Bashar', كريم: 'Karim', نور: 'Nour', هدى: 'Huda', سارة: 'Sara', ريم: 'Reem', لينا: 'Lina', رنا: 'Rana',
  فاطمة: 'Fatima', مريم: 'Maryam', عائشة: 'Aisha', زينب: 'Zeinab', ليلى: 'Layla', سلمى: 'Salma', دانا: 'Dana',
  عبد: 'Abd', الله: 'Allah', يزن: 'Yazan', عبدالله: 'Abdullah', عبدالرحمن: 'Abdulrahman', عبدالعزيز: 'Abdulaziz', عبدالكريم: 'Abdulkarim', عبدالقادر: 'Abdulqader',
  ابو: 'Abu', ابن: 'Ibn', بن: 'Bin', ام: 'Umm', الدين: 'Al-Din', ادلب: 'Idlib', دمشق: 'Damascus', حلب: 'Aleppo',
  حمص: 'Homs', حماة: 'Hama', اللاذقية: 'Latakia', طرطوس: 'Tartus', درعا: 'Daraa',
};

/** Place names are looked up locally: a dictionary translator turns "حمص" into "chickpeas". */
const PLACES: Record<string, string> = {
  سوريا: 'Syria', سورية: 'Syria', لبنان: 'Lebanon', الاردن: 'Jordan', العراق: 'Iraq', تركيا: 'Turkey', مصر: 'Egypt',
  السعودية: 'Saudi Arabia', الامارات: 'UAE', قطر: 'Qatar', الكويت: 'Kuwait', عمان: 'Oman', ليبيا: 'Libya', فلسطين: 'Palestine',
  دمشق: 'Damascus', حلب: 'Aleppo', حمص: 'Homs', حماة: 'Hama', اللاذقية: 'Latakia', طرطوس: 'Tartus', ادلب: 'Idlib',
  درعا: 'Daraa', السويداء: 'As-Suwayda', القنيطرة: 'Quneitra', الرقة: 'Raqqa', الحسكة: 'Al-Hasakah', القامشلي: 'Qamishli',
  'دير الزور': 'Deir ez-Zor', 'ريف دمشق': 'Rural Damascus', جرمانا: 'Jaramana', دوما: 'Douma', داريا: 'Daraya',
  المزة: 'Mezzeh', الفرقان: 'Al-Furqan', الشعلان: 'Shaalan', المالكي: 'Al-Malki', كفرسوسة: 'Kafr Sousa', المهاجرين: 'Muhajirin',
  'أبو رمانة': 'Abu Rummaneh', 'ابو رمانة': 'Abu Rummaneh', الميدان: 'Al-Midan', القصاع: 'Al-Qassaa', الصالحية: 'Al-Salhiyah',
  بيروت: 'Beirut', بغداد: 'Baghdad', القاهرة: 'Cairo', اسطنبول: 'Istanbul', الرياض: 'Riyadh', دبي: 'Dubai',
};

const LETTERS: Record<string, string> = {
  ا: 'a', ب: 'b', ت: 't', ث: 'th', ج: 'j', ح: 'h', خ: 'kh', د: 'd', ذ: 'dh', ر: 'r', ز: 'z', س: 's', ش: 'sh',
  ص: 's', ض: 'd', ط: 't', ظ: 'z', ع: 'a', غ: 'gh', ف: 'f', ق: 'q', ك: 'k', ل: 'l', م: 'm', ن: 'n', ه: 'h',
  و: 'w', ي: 'y', ى: 'a', ة: 'a', ء: '', ئ: 'e', ؤ: 'o', أ: 'a', إ: 'e', آ: 'a',
};

function lookupPlaces(value: string): string | null {
  const parts = value
    .split(/\s*[-–—،,/]\s*/)
    .map((part) => normaliseArabic(part))
    .filter(Boolean);
  if (!parts.length) return null;
  const found = parts.map((part) => PLACES[part]);
  return found.every(Boolean) ? found.join(', ') : null;
}

function normaliseArabic(value: string): string {
  return value
    .replace(/[\u064B-\u065F\u0670\u0640]/g, '')
    .replace(/[أإآ]/g, 'ا')
    .replace(/\s+/g, ' ')
    .trim();
}

function transliterateName(value: string): string {
  if (!/[\u0600-\u06FF]/.test(value)) return value;
  return value
    .split(/(\s+)/)
    .map((word) => (/\s+/.test(word) ? word : transliterateWord(word)))
    .join('');
}

function transliterateWord(word: string): string {
  const plain = word.replace(/[\u064B-\u065F\u0670\u0640]/g, '');
  const normalised = plain.replace(/[أإآ]/g, 'ا');
  if (NAMES[normalised]) return NAMES[normalised];
  if (normalised.startsWith('ال') && normalised.length > 3) {
    const rest = transliterateWord(normalised.slice(2));
    return `Al-${rest}`;
  }
  if (/^عبد[\u0600-\u06FF]{3,}$/.test(normalised)) {
    return `Abd${transliterateWord(normalised.slice(3)).toLowerCase()}`.replace(/^Abd(.)/, (_m, c: string) => `Abd${c.toUpperCase()}`);
  }
  const isVowelLetter = (c: string | undefined) => c !== undefined && 'اويىةعأإآ'.includes(c);
  let out = '';
  for (let i = 0; i < plain.length; i++) {
    const letter = plain[i];
    if (LETTERS[letter] === undefined) {
      out += /[A-Za-z0-9\-']/.test(letter) ? letter : '';
      continue;
    }
    if (letter === 'و') {
      out += i === 0 ? 'w' : 'ou';
    } else if (letter === 'ي') {
      out += i === 0 ? 'y' : 'i';
    } else {
      out += LETTERS[letter];
    }
    // Arabic omits short vowels: add an "a" between consonants so the name is pronounceable.
    const next = plain[i + 1];
    const consonant = !isVowelLetter(letter);
    if (consonant && next !== undefined && LETTERS[next] !== undefined && !isVowelLetter(next) && !/[aeiou](kh|sh|th|dh|gh|[^aeiou])$/.test(out)) {
      out += 'a';
    }
  }
  return out.charAt(0).toUpperCase() + out.slice(1);
}

function chunks(text: string): string[] {
  if (text.length <= CHUNK) return [text];
  const sentences = text.match(/[^.!?؟۔\n]+[.!?؟۔]*\s*/g) ?? [text];
  const out: string[] = [];
  let current = '';
  for (const sentence of sentences) {
    if ((current + sentence).length > CHUNK && current) {
      out.push(current.trim());
      current = '';
    }
    if (sentence.length > CHUNK) {
      for (let at = 0; at < sentence.length; at += CHUNK) out.push(sentence.slice(at, at + CHUNK).trim());
    } else {
      current += sentence;
    }
  }
  if (current.trim()) out.push(current.trim());
  return out;
}

function tidy(translated: string, original: string): string {
  const textarea = document.createElement('textarea');
  textarea.innerHTML = translated;
  let value = textarea.value.trim();
  if (!/[.!?؟]$/.test(original.trim()) && /\.$/.test(value) && !/\.\.$/.test(value)) value = value.slice(0, -1);
  return value;
}
