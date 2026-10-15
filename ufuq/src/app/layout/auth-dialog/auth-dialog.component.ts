import { NgTemplateOutlet } from '@angular/common';
import { Component, ElementRef, OnDestroy, computed, effect, inject, signal, untracked, viewChild } from '@angular/core';
import { AuthFailure, AuthService } from '../../core/auth.service';
import { AUTH_COPY, AuthErrorKey } from '../../core/auth-content';
import { AuthGate } from '../../core/auth-gate';
import { LanguageService } from '../../core/language.service';
import { PasswordFieldComponent } from '../password-field/password-field.component';

type View = 'login' | 'register' | 'verify' | 'forgot' | 'reset';
type Field = 'email' | 'password' | 'confirm' | 'firstName' | 'lastName' | 'phone' | 'code';

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const RESEND_AFTER = 60;

/**
 * The sign-in window. It is mounted once in the app shell and opened by `AuthGate` whenever a guest tries to
 * write a review or send a message. Everything the account system offers lives here: sign in, create an
 * account, confirm the email with a code, Google, and a forgotten password. It never knows which page opened
 * it; it only reports "signed in" or "closed" back to the gate.
 */
@Component({
  selector: 'app-auth-dialog',
  imports: [NgTemplateOutlet, PasswordFieldComponent],
  templateUrl: './auth-dialog.component.html',
  styleUrl: './auth-dialog.component.scss',
})
export class AuthDialogComponent implements OnDestroy {
  protected readonly gate = inject(AuthGate);
  private readonly auth = inject(AuthService);
  private readonly i18n = inject(LanguageService);
  private readonly dialog = viewChild<ElementRef<HTMLDialogElement>>('dlg');

  protected readonly copy = computed(() => AUTH_COPY[this.i18n.lang()]);
  protected readonly view = signal<View>('login');
  protected readonly busy = signal(false);
  protected readonly error = signal<AuthErrorKey | ''>('');
  protected readonly notice = signal('');
  protected readonly cooldown = signal(0);
  protected readonly form = signal<Record<Field, string>>(emptyForm());

  /** Kept in memory only, between "create account" and "confirm email", so the visitor is signed in at the end. */
  private pendingPassword = '';
  private timer: ReturnType<typeof setInterval> | null = null;
  private pressedOnBackdrop = false;

  constructor() {
    effect(() => {
      const reason = this.gate.request();
      const dialog = this.dialog()?.nativeElement;
      if (!dialog) return;
      if (reason) {
        if (dialog.open) return;
        untracked(() => this.reset());
        dialog.showModal();
        this.focusFirst();
      } else if (dialog.open) {
        dialog.close();
      }
    });
  }

  ngOnDestroy(): void {
    this.stopTimer();
  }

  protected setField(field: Field, event: Event): void {
    let value = (event.target as HTMLInputElement).value;
    if (field === 'code') value = value.replace(/\D/g, '').slice(0, 6);
    this.form.update((current) => ({ ...current, [field]: value }));
    this.error.set('');
  }

  protected setSecret(field: 'password' | 'confirm', value: string): void {
    this.form.update((current) => ({ ...current, [field]: value }));
    this.error.set('');
  }

  protected go(view: View, notice = ''): void {
    this.view.set(view);
    this.error.set('');
    this.notice.set(notice);
    this.form.update((current) => ({ ...emptyForm(), email: current.email }));
    this.focusFirst();
  }

  protected dismiss(): void {
    this.gate.finish(false);
  }

  /** The browser fires `close` for Escape too; tell the gate the visitor gave up. */
  protected onClosed(): void {
    this.stopTimer();
    if (this.gate.request()) this.gate.finish(false);
  }

  /** A click on the dimmed area closes the window, but not when a text selection merely ended there. */
  protected onPointerDown(event: MouseEvent): void {
    this.pressedOnBackdrop = event.target === this.dialog()?.nativeElement;
  }

  protected onClick(event: MouseEvent): void {
    if (this.pressedOnBackdrop && event.target === this.dialog()?.nativeElement) this.dismiss();
    this.pressedOnBackdrop = false;
  }

  // ----- steps

  protected async submitLogin(event: Event): Promise<void> {
    event.preventDefault();
    const { email, password } = this.form();
    if (!email.trim() || !password) return this.fail('invalid');
    if (!EMAIL.test(email.trim())) return this.fail('email');
    await this.run(async () => {
      try {
        await this.auth.login(email.trim(), password);
        this.done();
      } catch (error) {
        if (error instanceof AuthFailure && error.unverified) {
          // The account exists but its email was never confirmed: send a fresh code and ask for it.
          this.pendingPassword = password;
          try {
            await this.auth.resendCode(email.trim());
          } catch {
            /* a code sent a moment ago still works; the visitor can resend from the next step */
          }
          this.go('verify', this.copy().notices.needsVerify);
          this.startCooldown();
          return;
        }
        throw error;
      }
    });
  }

  protected async submitRegister(event: Event): Promise<void> {
    event.preventDefault();
    const f = this.form();
    const draft = {
      first_name: f.firstName.trim(),
      last_name: f.lastName.trim(),
      email: f.email.trim(),
      phone: f.phone.trim(),
      password: f.password,
      password_confirmation: f.confirm,
    };
    if (!draft.first_name || !draft.last_name || !draft.email || !draft.phone || !draft.password) return this.fail('invalid');
    if (!EMAIL.test(draft.email)) return this.fail('email');
    if (draft.password.length < 8) return this.fail('passwordShort');
    if (draft.password !== draft.password_confirmation) return this.fail('passwordMismatch');
    await this.run(async () => {
      await this.auth.register(draft);
      this.pendingPassword = draft.password;
      this.go('verify', this.copy().notices.codeSent);
      this.startCooldown();
    });
  }

  protected async submitVerify(event: Event): Promise<void> {
    event.preventDefault();
    const { email, code } = this.form();
    if (code.length !== 6) return this.fail('codeWrong');
    await this.run(async () => {
      await this.auth.verifyEmail(email, code);
      const password = this.pendingPassword;
      this.pendingPassword = '';
      if (password) {
        try {
          await this.auth.login(email, password);
          this.done();
          return;
        } catch {
          /* confirmed, but the automatic sign-in failed: let the visitor sign in by hand */
        }
      }
      this.go('login', this.copy().notices.verified);
    });
  }

  protected async resend(): Promise<void> {
    if (this.cooldown() > 0 || this.busy()) return;
    const email = this.form().email;
    await this.run(async () => {
      await this.auth.resendCode(email);
      this.notice.set(this.copy().notices.resent);
      this.startCooldown();
    });
  }

  protected async submitForgot(event: Event): Promise<void> {
    event.preventDefault();
    const email = this.form().email.trim();
    if (!email) return this.fail('invalid');
    if (!EMAIL.test(email)) return this.fail('email');
    await this.run(async () => {
      await this.auth.forgotPassword(email);
      this.form.update((current) => ({ ...current, email }));
      this.go('reset', this.copy().notices.codeSent);
    });
  }

  protected async submitReset(event: Event): Promise<void> {
    event.preventDefault();
    const { email, code, password, confirm } = this.form();
    if (code.length !== 6 || !password) return this.fail('invalid');
    if (password.length < 8) return this.fail('passwordShort');
    if (password !== confirm) return this.fail('passwordMismatch');
    await this.run(async () => {
      await this.auth.resetPassword(email, code, password, confirm);
      this.go('login', this.copy().notices.resetDone);
    });
  }

  protected async google(): Promise<void> {
    await this.run(async () => {
      await this.auth.google();
      this.done();
    });
  }

  // ----- helpers

  private async run(step: () => Promise<void>): Promise<void> {
    if (this.busy()) return;
    this.busy.set(true);
    this.error.set('');
    this.notice.set('');
    try {
      await step();
    } catch (error) {
      if (error instanceof AuthFailure) {
        if (!error.cancelled) this.error.set(error.key);
      } else {
        this.error.set('failed');
      }
    } finally {
      this.busy.set(false);
    }
  }

  private fail(key: AuthErrorKey): void {
    this.error.set(key);
  }

  private done(): void {
    this.pendingPassword = '';
    this.gate.finish(true);
  }

  private reset(): void {
    this.view.set('login');
    this.busy.set(false);
    this.error.set('');
    this.notice.set('');
    this.cooldown.set(0);
    this.stopTimer();
    this.pendingPassword = '';
    this.form.set(emptyForm());
  }

  private startCooldown(): void {
    this.stopTimer();
    this.cooldown.set(RESEND_AFTER);
    this.timer = setInterval(() => {
      this.cooldown.update((value) => Math.max(0, value - 1));
      if (this.cooldown() === 0) this.stopTimer();
    }, 1000);
  }

  private stopTimer(): void {
    if (this.timer) clearInterval(this.timer);
    this.timer = null;
  }

  private focusFirst(): void {
    requestAnimationFrame(() => {
      this.dialog()?.nativeElement.querySelector<HTMLInputElement>('form input:not([type="hidden"])')?.focus();
    });
  }
}

function emptyForm(): Record<Field, string> {
  return { email: '', password: '', confirm: '', firstName: '', lastName: '', phone: '', code: '' };
}
