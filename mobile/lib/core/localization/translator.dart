import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ufuq_imperium/core/localization/copy.dart';

const _storeKey = 'ufuq-translations-v1';
const _storeLimit = 600;
const _endpoint = 'https://api.mymemory.translated.net/get';
const _chunk = 440;
const _parallel = 5;
const _retryAfter = Duration(minutes: 5);
const _cooldown = Duration(minutes: 15);

final _arabic = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
final _latin = RegExp(r'[A-Za-z]');

/// Translates text that comes from the API (the backend stores one language only).
/// Arabic content is shown in English when the app is English. Results are cached in
/// memory and on disk, so every string is requested at most once per install.
class Translator extends ChangeNotifier {
  Translator({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, String> _cache = {};
  final Map<String, ({Lang target, String text})> _queue = {};
  final Map<String, DateTime> _failed = {};
  Timer? _timer;
  Timer? _notify;
  Timer? _persistTimer;
  int _running = 0;
  DateTime _pausedUntil = DateTime.fromMillisecondsSinceEpoch(0);
  bool _disposed = false;

  Lang lang = Lang.ar;

  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storeKey);
      if (raw == null) return;
      final parsed = jsonDecode(raw);
      if (parsed is List) {
        for (final entry in parsed) {
          if (entry is List && entry.length == 2) {
            _cache['${entry[0]}'] = '${entry[1]}';
          }
        }
      }
    } catch (_) {}
  }

  /// The cached translation, or the original while it is fetched in the background.
  /// The caller rebuilds when [notifyListeners] fires.
  String text(String? value) {
    final original = value ?? '';
    if (!needsTranslation(original, lang)) return original;
    final place = _lookupPlaces(original);
    if (place != null) return place;
    final key = _keyOf(lang, original);
    final hit = _cache[key];
    if (hit != null) return hit;
    _enqueue(key, lang, original);
    return original;
  }

  /// People's names are transliterated locally (never translated by meaning).
  String name(String? value) {
    final original = value ?? '';
    if (lang != Lang.en) return original;
    return _transliterateName(original);
  }

  String? maybe(String? value) => value == null ? null : text(value);

  void _enqueue(String key, Lang target, String text) {
    if (_queue.containsKey(key)) return;
    final failedAt = _failed[key];
    if (failedAt != null && DateTime.now().difference(failedAt) < _retryAfter) {
      return;
    }
    _queue[key] = (target: target, text: text);
    _timer ??= Timer(const Duration(milliseconds: 40), _flush);
  }

  void _flush() {
    _timer = null;
    if (_disposed) return;
    final now = DateTime.now();
    if (now.isBefore(_pausedUntil)) {
      _timer = Timer(_pausedUntil.difference(now), _flush);
      return;
    }
    while (_running < _parallel && _queue.isNotEmpty) {
      final key = _queue.keys.first;
      final job = _queue.remove(key)!;
      _running += 1;
      _translate(job.text, job.target)
          .then((result) {
            if (result == null) {
              _failed[key] = DateTime.now();
            } else {
              _cache[key] = result;
              _scheduleNotify();
              _schedulePersist();
            }
          })
          .whenComplete(() {
            _running -= 1;
            if (_queue.isNotEmpty) _flush();
          });
    }
  }

  // Many strings resolve at nearly the same time: rebuild once per burst.
  void _scheduleNotify() {
    _notify ??= Timer(const Duration(milliseconds: 120), () {
      _notify = null;
      if (!_disposed) notifyListeners();
    });
  }

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(seconds: 2), () async {
      try {
        final entries = _cache.entries.toList();
        final slice = entries.length > _storeLimit
            ? entries.sublist(entries.length - _storeLimit)
            : entries;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _storeKey,
          jsonEncode([
            for (final e in slice) [e.key, e.value],
          ]),
        );
      } catch (_) {}
    });
  }

  Future<String?> _translate(String text, Lang target) async {
    final source = target == Lang.en ? Lang.ar : Lang.en;
    final parts = _splitKeepingNewlines(text);
    final out = StringBuffer();
    for (final part in parts) {
      if (part.trim().isEmpty || RegExp(r'^\n+$').hasMatch(part)) {
        out.write(part);
        continue;
      }
      final lead = RegExp(r'^\s*').firstMatch(part)?.group(0) ?? '';
      final trail = RegExp(r'\s*$').firstMatch(part)?.group(0) ?? '';
      final pieces = <String>[];
      for (final piece in _chunks(part.trim())) {
        final done = await _request(piece, source, target);
        if (done == null) return null;
        pieces.add(done);
      }
      out.write('$lead${pieces.join(' ')}$trail');
    }
    return out.toString();
  }

  Future<String?> _request(String chunk, Lang source, Lang target) async {
    if (!needsTranslation(chunk, target)) return chunk;
    try {
      final uri = Uri.parse(_endpoint).replace(
        queryParameters: {
          'q': chunk,
          'langpair': '${source.name}|${target.name}',
        },
      );
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 429) {
        _pausedUntil = DateTime.now().add(_cooldown);
        return null;
      }
      if (response.statusCode != 200) return null;
      final body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (body['quotaFinished'] == true) {
        _pausedUntil = DateTime.now().add(_cooldown);
        return null;
      }
      if ('${body['responseStatus']}' != '200') return null;
      var translated =
          (body['responseData'] as Map?)?['translatedText'] as String?;
      if (translated == null || translated.isEmpty) return null;
      if (RegExp(
        r'MYMEMORY WARNING|QUERY LENGTH LIMIT',
        caseSensitive: false,
      ).hasMatch(translated)) {
        return null;
      }
      if (needsTranslation(translated, target)) {
        // Single words often come back untouched; the alternative matches usually hold the real translation.
        final matches =
            (body['matches'] as List? ?? const []).whereType<Map>().where((m) {
                final t = m['translation'];
                return t is String &&
                    !needsTranslation(t, target) &&
                    !RegExp('MYMEMORY', caseSensitive: false).hasMatch(t);
              }).toList()
              ..sort((a, b) => _num(b['match']).compareTo(_num(a['match'])));
        if (matches.isEmpty) return null;
        translated = matches.first['translation'] as String;
        if (translated == translated.toUpperCase() && chunk.length < 40) {
          translated = translated[0] + translated.substring(1).toLowerCase();
        }
      }
      return _tidy(translated, chunk);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _notify?.cancel();
    _persistTimer?.cancel();
    super.dispose();
  }
}

double _num(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

String _keyOf(Lang target, String text) => '${target.name}\u0001$text';

List<String> _splitKeepingNewlines(String text) {
  final out = <String>[];
  var last = 0;
  for (final match in RegExp(r'\n+').allMatches(text)) {
    out.add(text.substring(last, match.start));
    out.add(match.group(0)!);
    last = match.end;
  }
  out.add(text.substring(last));
  return out;
}

bool needsTranslation(String value, Lang target) {
  final text = value.trim();
  if (text.length < 2) return false;
  if (RegExp(r'^(https?://|www\.)', caseSensitive: false).hasMatch(text) ||
      RegExp(r'\S+@\S+\.\S+').hasMatch(text)) {
    return false;
  }
  if (!RegExp(r'\p{L}', unicode: true).hasMatch(text)) return false;
  final arabic = _arabic.allMatches(text).length;
  final latin = _latin.allMatches(text).length;
  // Only Arabic -> English: Latin text on the Arabic site is usually a name or a brand.
  return target == Lang.en && arabic > 0 && arabic * 2 >= latin;
}

const _names = <String, String>{
  'محمد': 'Mohammed',
  'احمد': 'Ahmad',
  'علي': 'Ali',
  'عمر': 'Omar',
  'خالد': 'Khaled',
  'يوسف': 'Yousef',
  'ابراهيم': 'Ibrahim',
  'حسن': 'Hassan',
  'حسين': 'Hussein',
  'مصطفى': 'Mustafa',
  'محمود': 'Mahmoud',
  'عثمان': 'Othman',
  'سامر': 'Samer',
  'سامي': 'Sami',
  'فادي': 'Fadi',
  'وليد': 'Walid',
  'طارق': 'Tarek',
  'زياد': 'Ziad',
  'ياسر': 'Yasser',
  'ماهر': 'Maher',
  'رامي': 'Rami',
  'باسل': 'Basel',
  'بشار': 'Bashar',
  'كريم': 'Karim',
  'نور': 'Nour',
  'هدى': 'Huda',
  'سارة': 'Sara',
  'ريم': 'Reem',
  'لينا': 'Lina',
  'رنا': 'Rana',
  'فاطمة': 'Fatima',
  'مريم': 'Maryam',
  'عائشة': 'Aisha',
  'زينب': 'Zeinab',
  'ليلى': 'Layla',
  'سلمى': 'Salma',
  'دانا': 'Dana',
  'عبد': 'Abd',
  'الله': 'Allah',
  'يزن': 'Yazan',
  'عبدالله': 'Abdullah',
  'عبدالرحمن': 'Abdulrahman',
  'عبدالعزيز': 'Abdulaziz',
  'عبدالكريم': 'Abdulkarim',
  'عبدالقادر': 'Abdulqader',
  'ابو': 'Abu',
  'ابن': 'Ibn',
  'بن': 'Bin',
  'ام': 'Umm',
  'الدين': 'Al-Din',
  'ادلب': 'Idlib',
  'دمشق': 'Damascus',
  'حلب': 'Aleppo',
  'حمص': 'Homs',
  'حماة': 'Hama',
  'اللاذقية': 'Latakia',
  'طرطوس': 'Tartus',
  'درعا': 'Daraa',
};

/// Place names are looked up locally: a dictionary translator turns "حمص" into "chickpeas".
const _places = <String, String>{
  'سوريا': 'Syria',
  'سورية': 'Syria',
  'لبنان': 'Lebanon',
  'الاردن': 'Jordan',
  'العراق': 'Iraq',
  'تركيا': 'Turkey',
  'مصر': 'Egypt',
  'السعودية': 'Saudi Arabia',
  'الامارات': 'UAE',
  'قطر': 'Qatar',
  'الكويت': 'Kuwait',
  'عمان': 'Oman',
  'ليبيا': 'Libya',
  'فلسطين': 'Palestine',
  'دمشق': 'Damascus',
  'حلب': 'Aleppo',
  'حمص': 'Homs',
  'حماة': 'Hama',
  'اللاذقية': 'Latakia',
  'طرطوس': 'Tartus',
  'ادلب': 'Idlib',
  'درعا': 'Daraa',
  'السويداء': 'As-Suwayda',
  'القنيطرة': 'Quneitra',
  'الرقة': 'Raqqa',
  'الحسكة': 'Al-Hasakah',
  'القامشلي': 'Qamishli',
  'دير الزور': 'Deir ez-Zor',
  'ريف دمشق': 'Rural Damascus',
  'جرمانا': 'Jaramana',
  'دوما': 'Douma',
  'داريا': 'Daraya',
  'المزة': 'Mezzeh',
  'الفرقان': 'Al-Furqan',
  'الشعلان': 'Shaalan',
  'المالكي': 'Al-Malki',
  'كفرسوسة': 'Kafr Sousa',
  'المهاجرين': 'Muhajirin',
  'ابو رمانة': 'Abu Rummaneh',
  'الميدان': 'Al-Midan',
  'القصاع': 'Al-Qassaa',
  'الصالحية': 'Al-Salhiyah',
  'بيروت': 'Beirut',
  'بغداد': 'Baghdad',
  'القاهرة': 'Cairo',
  'اسطنبول': 'Istanbul',
  'الرياض': 'Riyadh',
  'دبي': 'Dubai',
};

const _letters = <String, String>{
  'ا': 'a',
  'ب': 'b',
  'ت': 't',
  'ث': 'th',
  'ج': 'j',
  'ح': 'h',
  'خ': 'kh',
  'د': 'd',
  'ذ': 'dh',
  'ر': 'r',
  'ز': 'z',
  'س': 's',
  'ش': 'sh',
  'ص': 's',
  'ض': 'd',
  'ط': 't',
  'ظ': 'z',
  'ع': 'a',
  'غ': 'gh',
  'ف': 'f',
  'ق': 'q',
  'ك': 'k',
  'ل': 'l',
  'م': 'm',
  'ن': 'n',
  'ه': 'h',
  'و': 'w',
  'ي': 'y',
  'ى': 'a',
  'ة': 'a',
  'ء': '',
  'ئ': 'e',
  'ؤ': 'o',
  'أ': 'a',
  'إ': 'e',
  'آ': 'a',
};

final _diacritics = RegExp(r'[\u064B-\u065F\u0670\u0640]');

String? _lookupPlaces(String value) {
  final parts = value
      .split(RegExp(r'\s*[-–—،,/]\s*'))
      .map(_normaliseArabic)
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return null;
  final found = parts.map((part) => _places[part]).toList();
  return found.every((item) => item != null) ? found.join(', ') : null;
}

String _normaliseArabic(String value) => value
    .replaceAll(_diacritics, '')
    .replaceAll(RegExp(r'[أإآ]'), 'ا')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String _transliterateName(String value) {
  if (!RegExp(r'[\u0600-\u06FF]').hasMatch(value)) return value;
  return value.splitMapJoin(
    RegExp(r'\s+'),
    onMatch: (m) => m.group(0)!,
    onNonMatch: _transliterateWord,
  );
}

String _transliterateWord(String word) {
  if (word.isEmpty) return word;
  final plain = word.replaceAll(_diacritics, '');
  final normalised = plain.replaceAll(RegExp(r'[أإآ]'), 'ا');
  final known = _names[normalised];
  if (known != null) return known;
  if (normalised.startsWith('ال') && normalised.length > 3) {
    return 'Al-${_transliterateWord(normalised.substring(2))}';
  }
  if (RegExp(r'^عبد[\u0600-\u06FF]{3,}$').hasMatch(normalised)) {
    final rest = _transliterateWord(normalised.substring(3)).toLowerCase();
    return 'Abd${rest[0].toUpperCase()}${rest.substring(1)}';
  }
  bool isVowel(String? c) => c != null && 'اويىةعأإآ'.contains(c);
  final out = StringBuffer();
  final chars = plain.split('');
  for (var i = 0; i < chars.length; i++) {
    final letter = chars[i];
    if (!_letters.containsKey(letter)) {
      if (RegExp(r"[A-Za-z0-9\-']").hasMatch(letter)) out.write(letter);
      continue;
    }
    if (letter == 'و') {
      out.write(i == 0 ? 'w' : 'ou');
    } else if (letter == 'ي') {
      out.write(i == 0 ? 'y' : 'i');
    } else {
      out.write(_letters[letter]);
    }
    // Arabic omits short vowels: add an "a" between consonants so the name is pronounceable.
    final next = i + 1 < chars.length ? chars[i + 1] : null;
    final consonant = !isVowel(letter);
    if (consonant &&
        next != null &&
        _letters.containsKey(next) &&
        !isVowel(next) &&
        !RegExp(r'[aeiou](kh|sh|th|dh|gh|[^aeiou])$')
            .hasMatch(out.toString())) {
      out.write('a');
    }
  }
  final text = out.toString();
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

List<String> _chunks(String text) {
  if (text.length <= _chunk) return [text];
  final sentences = RegExp(r'[^.!?؟۔\n]+[.!?؟۔]*\s*')
      .allMatches(text)
      .map((m) => m.group(0)!)
      .toList();
  final out = <String>[];
  var current = '';
  for (final sentence in (sentences.isEmpty ? [text] : sentences)) {
    if ((current + sentence).length > _chunk && current.isNotEmpty) {
      out.add(current.trim());
      current = '';
    }
    if (sentence.length > _chunk) {
      for (var at = 0; at < sentence.length; at += _chunk) {
        final end = at + _chunk > sentence.length
            ? sentence.length
            : at + _chunk;
        out.add(sentence.substring(at, end).trim());
      }
    } else {
      current += sentence;
    }
  }
  if (current.trim().isNotEmpty) out.add(current.trim());
  return out;
}

String _tidy(String translated, String original) {
  var value = translated
      .replaceAllMapped(
        RegExp(r'&#(\d+);'),
        (m) => String.fromCharCode(int.parse(m.group(1)!)),
      )
      .replaceAllMapped(
        RegExp(r'&#x([0-9a-fA-F]+);'),
        (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
      )
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .trim();
  if (!RegExp(r'[.!?؟]$').hasMatch(original.trim()) &&
      value.endsWith('.') &&
      !value.endsWith('..')) {
    value = value.substring(0, value.length - 1);
  }
  return value;
}
