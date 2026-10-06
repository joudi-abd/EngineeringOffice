import { Injectable, effect, signal } from '@angular/core';

export type ThemeMode = 'light' | 'dark';

const STORAGE_KEY = 'ufuq-dashboard-theme';

@Injectable({ providedIn: 'root' })
export class ThemeService {
  readonly mode = signal<ThemeMode>(readTheme());

  constructor() {
    effect(() => applyTheme(this.mode()));
  }

  toggle(): void {
    this.mode.update((mode) => (mode === 'dark' ? 'light' : 'dark'));
  }
}

export function readTheme(): ThemeMode {
  try {
    return localStorage.getItem(STORAGE_KEY) === 'light' ? 'light' : 'dark';
  } catch {
    return 'dark';
  }
}

export function applyTheme(mode: ThemeMode): void {
  document.documentElement.dataset['theme'] = mode;
  try {
    localStorage.setItem(STORAGE_KEY, mode);
  } catch {
    /* storage may be unavailable */
  }
}
