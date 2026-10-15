import { DOCUMENT } from '@angular/common';
import { Injectable, effect, inject, signal } from '@angular/core';
import { Meta } from '@angular/platform-browser';
import { Lang } from './site-content';

export type Theme = 'dark' | 'light';

const KEY = 'ufuq-theme';
const BAR: Record<Theme, string> = { dark: '#000000', light: '#f7f3ec' };

export const THEME_COPY: Record<Lang, { toLight: string; toDark: string }> = {
  ar: { toLight: 'التبديل إلى الوضع النهاري', toDark: 'التبديل إلى الوضع الليلي' },
  en: { toLight: 'Switch to light mode', toDark: 'Switch to dark mode' },
};

/**
 * Light or dark. A visitor who never chose gets their device's setting and follows it when it changes; the
 * first time they press the toggle their choice is saved and wins from then on. The palette itself lives in
 * theme.scss, keyed on `<html data-theme>`, and index.html sets the attribute before first paint (no flash).
 */
@Injectable({ providedIn: 'root' })
export class ThemeService {
  private readonly doc = inject(DOCUMENT);
  private readonly meta = inject(Meta);
  private chosen = this.saved() !== null;

  readonly theme = signal<Theme>(this.saved() ?? this.system());

  constructor() {
    effect(() => {
      const theme = this.theme();
      this.doc.documentElement.dataset['theme'] = theme;
      this.meta.updateTag({ name: 'theme-color', content: BAR[theme] });
    });
    const query = this.doc.defaultView?.matchMedia?.('(prefers-color-scheme: light)');
    query?.addEventListener('change', () => {
      if (!this.chosen) this.theme.set(this.system());
    });
  }

  toggle(): void {
    const root = this.doc.documentElement;
    root.classList.add('theme-fade');
    setTimeout(() => root.classList.remove('theme-fade'), 450);
    this.chosen = true;
    this.theme.update((theme) => (theme === 'dark' ? 'light' : 'dark'));
    try {
      localStorage.setItem(KEY, this.theme());
    } catch {
      /* storage may be unavailable: the choice then lasts until the page closes */
    }
  }

  private saved(): Theme | null {
    try {
      const value = localStorage.getItem(KEY);
      return value === 'light' || value === 'dark' ? value : null;
    } catch {
      return null;
    }
  }

  private system(): Theme {
    return this.doc.defaultView?.matchMedia?.('(prefers-color-scheme: light)').matches ? 'light' : 'dark';
  }
}
