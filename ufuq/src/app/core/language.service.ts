import { Injectable, computed, effect, inject, signal } from '@angular/core';
import { Meta, Title } from '@angular/platform-browser';
import { CONTENT, Lang } from './site-content';

@Injectable({ providedIn: 'root' })
export class LanguageService {
  private readonly title = inject(Title);
  private readonly meta = inject(Meta);

  readonly lang = signal<Lang>(this.readLang());
  readonly content = computed(() => CONTENT[this.lang()]);
  readonly pageKind = signal<'home' | 'about' | 'services' | 'projects' | 'project'>('home');
  readonly pageMeta = signal<{ title: string; description: string } | null>(null);

  constructor() {
    effect(() => {
      const lang = this.lang();
      const content = CONTENT[lang];
      const kind = this.pageKind();
      const custom = this.pageMeta();
      const page =
        kind === 'about' ? content.aboutPage :
        kind === 'services' ? content.servicesPage :
        kind === 'projects' ? content.projectsPage :
        null;
      document.documentElement.lang = lang;
      document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';
      try {
        localStorage.setItem('ufuq-lang', lang);
      } catch {
        /* storage may be unavailable */
      }
      this.title.setTitle(custom?.title ?? page?.metaTitle ?? content.metaTitle);
      this.meta.updateTag({
        name: 'description',
        content: custom?.description ?? page?.metaDescription ?? content.metaDescription,
      });
    });
  }

  toggle(): void {
    this.lang.update((lang) => (lang === 'ar' ? 'en' : 'ar'));
  }

  private readLang(): Lang {
    try {
      const saved = localStorage.getItem('ufuq-lang');
      if (saved === 'ar' || saved === 'en') return saved;
    } catch {
      /* storage may be unavailable */
    }
    return 'ar';
  }
}
