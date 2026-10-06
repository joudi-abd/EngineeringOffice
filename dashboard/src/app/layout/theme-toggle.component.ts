import { Component, computed, inject } from '@angular/core';
import { ThemeService } from '../core/theme.service';

@Component({
  selector: 'app-theme-toggle',
  template: `
    <button class="icon-btn" type="button" (click)="theme.toggle()" [attr.aria-label]="label()">
      @if (theme.mode() === 'dark') {
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <circle cx="12" cy="12" r="4" />
          <path d="M12 2.4v2.3M12 19.3v2.3M2.4 12h2.3M19.3 12h2.3M5.1 5.1l1.6 1.6M17.3 17.3l1.6 1.6M18.9 5.1l-1.6 1.6M6.7 17.3l-1.6 1.6" />
        </svg>
      } @else {
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path d="M16.2 3.4A8.2 8.2 0 1 0 20.6 16 8.4 8.4 0 0 1 16.2 3.4z" />
        </svg>
      }
    </button>
  `,
})
export class ThemeToggleComponent {
  protected readonly theme = inject(ThemeService);
  protected readonly label = computed(() => (this.theme.mode() === 'dark' ? 'الوضع النهاري' : 'الوضع الليلي'));
}
