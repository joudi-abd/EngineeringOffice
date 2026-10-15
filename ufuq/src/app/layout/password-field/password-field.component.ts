import { Component, computed, inject, input, model, signal } from '@angular/core';
import { AUTH_COPY } from '../../core/auth-content';
import { LanguageService } from '../../core/language.service';

/**
 * A password input with an eye that shows or hides what was typed. Used by the sign-in window and the profile
 * page so the two behave and look the same. The text always runs left to right, as passwords do in both languages.
 */
@Component({
  selector: 'app-password-field',
  templateUrl: './password-field.component.html',
  styleUrl: './password-field.component.scss',
})
export class PasswordFieldComponent {
  private readonly i18n = inject(LanguageService);

  readonly label = input.required<string>();
  readonly autocomplete = input('new-password');
  readonly hint = input('');
  readonly value = model('');

  protected readonly shown = signal(false);
  protected readonly copy = computed(() => AUTH_COPY[this.i18n.lang()]);

  protected type(): 'text' | 'password' {
    return this.shown() ? 'text' : 'password';
  }

  protected edit(event: Event): void {
    this.value.set((event.target as HTMLInputElement).value);
  }

  protected toggle(): void {
    this.shown.update((on) => !on);
  }
}
