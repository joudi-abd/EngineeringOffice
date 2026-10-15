import { Component, OnDestroy, computed, effect, inject, signal } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { AuthFailure, AuthService } from '../../core/auth.service';
import { AUTH_COPY, AuthErrorKey } from '../../core/auth-content';
import { LanguageService } from '../../core/language.service';
import { PROFILE_COPY } from '../../core/profile-content';
import { SectionNav } from '../../core/section-nav';
import { PasswordFieldComponent } from '../../layout/password-field/password-field.component';

const RESEND_AFTER = 60;

interface Row {
  key: string;
  label: string;
  value: string;
  /** `ok` and `warn` draw the value as a small badge. */
  tone?: 'ok' | 'warn';
  ltr?: boolean;
}

/**
 * The signed-in visitor's account page: the details the API holds (read only, the API has no way to edit them),
 * and a password change done with the same emailed code the sign-in window uses for a forgotten password.
 * Guests never reach it: `profileGuard` opens the sign-in window first.
 */
@Component({
  selector: 'app-profile',
  imports: [RouterLink, PasswordFieldComponent],
  templateUrl: './profile.component.html',
  styleUrl: './profile.component.scss',
})
export class ProfileComponent implements OnDestroy {
  protected readonly i18n = inject(LanguageService);
  protected readonly auth = inject(AuthService);
  protected readonly sections = inject(SectionNav);
  private readonly router = inject(Router);

  protected readonly copy = computed(() => PROFILE_COPY[this.i18n.lang()]);
  protected readonly authCopy = computed(() => AUTH_COPY[this.i18n.lang()]);

  protected readonly step = signal<'idle' | 'code'>('idle');
  protected readonly code = signal('');
  protected readonly password = signal('');
  protected readonly confirm = signal('');
  protected readonly busy = signal(false);
  protected readonly error = signal<AuthErrorKey | ''>('');
  protected readonly notice = signal('');
  protected readonly cooldown = signal(0);
  /** True once the password was changed: the page then shows the confirmation instead of the account. */
  protected readonly changed = signal(false);

  protected readonly initials = computed(() => {
    const user = this.auth.user();
    if (!user) return '';
    const letters = [user.first_name, user.last_name]
      .filter((part): part is string => !!part?.trim())
      .map((part) => Array.from(part.trim())[0]);
    return (letters.length ? letters.join('') : Array.from(user.email)[0]).toUpperCase();
  });

  protected readonly rows = computed<Row[]>(() => {
    const user = this.auth.user();
    const c = this.copy().details;
    const lang = this.i18n.lang();
    if (!user) return [];
    const verified = !!user.email_verified_at;
    const none = c.empty;
    const date = (value: string | null | undefined): string => formatDate(value, lang) || none;
    return [
      { key: 'first', label: c.firstName, value: user.first_name?.trim() || none },
      { key: 'last', label: c.lastName, value: user.last_name?.trim() || none },
      { key: 'email', label: c.email, value: user.email, ltr: true },
      { key: 'verified', label: c.emailStatus, value: verified ? c.verified : c.unverified, tone: verified ? 'ok' : 'warn' },
      { key: 'phone', label: c.phone, value: user.phone?.trim() || none, ltr: !!user.phone?.trim() },
      { key: 'google', label: c.google, value: user.google_id ? c.linked : c.notLinked },
      { key: 'since', label: c.memberSince, value: date(user.created_at) },
      { key: 'login', label: c.lastLogin, value: date(user.last_login_at) },
    ];
  });

  private email = '';
  private timer: ReturnType<typeof setInterval> | null = null;

  constructor() {
    void this.auth.refresh();
    effect(() => {
      const c = this.copy();
      this.i18n.pageMeta.set({ title: c.metaTitle, description: c.metaDescription });
    });
    // Signed out from elsewhere (the header, an expired session): there is nothing to show here any more.
    effect(() => {
      if (!this.auth.user() && !this.changed()) void this.router.navigateByUrl('/');
    });
  }

  ngOnDestroy(): void {
    this.stopTimer();
    this.i18n.pageMeta.set(null);
  }

  protected setCode(event: Event): void {
    this.code.set((event.target as HTMLInputElement).value.replace(/\D/g, '').slice(0, 6));
    this.error.set('');
  }

  protected signOut(): void {
    void this.auth.logout().then(() => this.router.navigateByUrl('/'));
  }

  protected async sendCode(): Promise<void> {
    if (this.busy() || this.cooldown() > 0) return;
    const email = this.auth.user()?.email ?? this.email;
    if (!email) return;
    await this.run(async () => {
      await this.auth.forgotPassword(email);
      this.email = email;
      this.step.set('code');
      this.notice.set(this.copy().security.sent);
      this.startCooldown();
    });
  }

  protected async save(event: Event): Promise<void> {
    event.preventDefault();
    const code = this.code();
    const password = this.password();
    if (code.length !== 6 || !password) return this.error.set('invalid');
    if (password.length < 8) return this.error.set('passwordShort');
    if (password !== this.confirm()) return this.error.set('passwordMismatch');
    await this.run(async () => {
      await this.auth.resetPassword(this.email, code, password, this.confirm());
      // The API closes every session of this account when the password changes, this one included.
      this.changed.set(true);
      this.stopTimer();
      await this.auth.logout();
    });
  }

  private async run(step: () => Promise<void>): Promise<void> {
    this.busy.set(true);
    this.error.set('');
    this.notice.set('');
    try {
      await step();
    } catch (error) {
      this.error.set(error instanceof AuthFailure ? error.key : 'failed');
    } finally {
      this.busy.set(false);
    }
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
}

function formatDate(value: string | null | undefined, lang: 'ar' | 'en'): string {
  if (!value) return '';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '';
  return new Intl.DateTimeFormat(lang === 'ar' ? 'ar-u-nu-latn' : 'en-GB', { dateStyle: 'long' }).format(date);
}
