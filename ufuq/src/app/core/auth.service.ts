import { HttpClient, HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { Injectable, Injector, computed, inject, signal } from '@angular/core';
import { catchError, firstValueFrom, throwError } from 'rxjs';
import { FirebaseAuthService } from '../services/firebase.auth.service';
import { ApiConfig } from './api-config';
import { AuthErrorKey } from './auth-content';

/** The signed-in account, as the API returns it (`GET /auth/me`). */
export interface AuthUser {
  id: number;
  first_name: string | null;
  last_name: string | null;
  email: string;
  phone?: string | null;
  status?: string | null;
  /** Set once the email was confirmed with a code. */
  email_verified_at?: string | null;
  last_login_at?: string | null;
  created_at?: string | null;
  /** Present when the account was linked to Google. Only its presence is used, never the value. */
  google_id?: string | null;
}

export interface RegisterDraft {
  first_name: string;
  last_name: string;
  email: string;
  phone: string;
  password: string;
  password_confirmation: string;
}

/** A failed step, already reduced to a key that has a sentence in both languages. */
export class AuthFailure extends Error {
  constructor(
    readonly key: AuthErrorKey,
    /** The account exists but its email is not confirmed yet (login answered 403 with `email_verified: false`). */
    readonly unverified = false,
    /** The visitor closed Google's window on purpose: nothing to report. */
    readonly cancelled = false,
  ) {
    super(key);
  }
}

const TOKEN_KEY = 'access_token';

export function readToken(): string {
  try {
    return localStorage.getItem(TOKEN_KEY) ?? '';
  } catch {
    return '';
  }
}

/** Adds the account's token to calls to the site's own API, and forgets the account if the API refuses it. */
export const authInterceptor: HttpInterceptorFn = (request, next) => {
  const config = inject(ApiConfig);
  const injector = inject(Injector);
  const token = readToken();
  if (!token || !request.url.startsWith(config.apiUrl)) return next(request);
  return next(request.clone({ setHeaders: { Authorization: `Bearer ${token}` } })).pipe(
    catchError((error: unknown) => {
      if (error instanceof HttpErrorResponse && error.status === 401) injector.get(AuthService).expire();
      return throwError(() => error);
    }),
  );
};

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly http = inject(HttpClient);
  private readonly config = inject(ApiConfig);
  private readonly firebase = inject(FirebaseAuthService);

  readonly user = signal<AuthUser | null>(null);
  readonly loggedIn = computed(() => this.user() !== null);
  /** The name to show: first and last name, or the email when the account has neither. */
  readonly displayName = computed(() => {
    const user = this.user();
    if (!user) return '';
    return [user.first_name, user.last_name].filter(Boolean).join(' ').trim() || user.email;
  });

  private restoring: Promise<void> | null = null;

  /** Checks a saved token with the API once, at start-up. Safe to call again: it only runs once. */
  restore(): Promise<void> {
    this.restoring ??= this.check();
    return this.restoring;
  }

  /** Reads the account again from the API, so the profile page never shows stale details. */
  async refresh(): Promise<void> {
    if (!readToken()) return;
    try {
      this.user.set(await firstValueFrom(this.http.get<AuthUser>(this.url('/auth/me'))));
    } catch {
      /* a 401 is handled by the interceptor; offline keeps what is already shown */
    }
  }

  /** Resolves when the saved session has been checked, so a click never races the start-up check. */
  whenReady(): Promise<void> {
    return this.restore();
  }

  async login(email: string, password: string): Promise<void> {
    try {
      const body = await firstValueFrom(
        this.http.post<{ access_token: string; user: AuthUser }>(this.url('/auth/login'), { email, password }),
      );
      this.begin(body.access_token, body.user);
    } catch (error) {
      throw failure(error, 'login');
    }
  }

  async register(draft: RegisterDraft): Promise<void> {
    await this.call('/auth/register', draft, 'register');
  }

  async verifyEmail(email: string, code: string): Promise<void> {
    try {
      await firstValueFrom(this.http.post(this.url('/auth/verify-email'), { email, code }));
    } catch (error) {
      // "Email is already verified": the goal is reached, so it is not an error for the visitor.
      const said = error instanceof HttpErrorResponse ? JSON.stringify(error.error ?? '') : '';
      if (error instanceof HttpErrorResponse && error.status === 422 && /already verified/i.test(said)) return;
      throw failure(error, 'verify');
    }
  }

  async resendCode(email: string): Promise<void> {
    await this.call('/auth/resend-verification-code', { email }, 'resend');
  }

  async forgotPassword(email: string): Promise<void> {
    await this.call('/auth/forgot-password', { email }, 'forgot');
  }

  async resetPassword(email: string, code: string, password: string, confirmation: string): Promise<void> {
    await this.call(
      '/auth/reset-password',
      { email, code, password, password_confirmation: confirmation },
      'reset',
    );
  }

  /** Google's window, then the API swaps the Firebase token for this site's own session. */
  async google(): Promise<void> {
    let idToken: string;
    try {
      idToken = await this.firebase.googleIdToken();
    } catch (error) {
      throw googleWindowFailure(error);
    }
    try {
      const body = await firstValueFrom(
        this.http.post<{ data: { user: AuthUser; token: string } }>(this.url('/auth/google'), { id_token: idToken }),
      );
      this.begin(body.data.token, body.data.user);
    } catch (error) {
      await this.firebase.signOut();
      throw failure(error, 'google');
    }
  }

  async logout(): Promise<void> {
    const had = readToken() !== '';
    if (had) {
      try {
        await firstValueFrom(this.http.post(this.url('/auth/logout'), {}));
      } catch {
        /* the token may already be gone on the server; it is dropped here either way */
      }
    }
    this.expire();
    await this.firebase.signOut();
  }

  /** Forgets the account on this device (the API refused the token, or the visitor signed out). */
  expire(): void {
    this.user.set(null);
    this.saveToken('');
  }

  private async check(): Promise<void> {
    if (!readToken()) return;
    try {
      this.user.set(await firstValueFrom(this.http.get<AuthUser>(this.url('/auth/me'))));
    } catch {
      // A 401 is handled by the interceptor (it clears the token). Offline: stay signed out for now.
    }
  }

  private begin(token: string, user: AuthUser): void {
    this.saveToken(token);
    this.user.set(user);
  }

  private saveToken(token: string): void {
    try {
      if (token) localStorage.setItem(TOKEN_KEY, token);
      else localStorage.removeItem(TOKEN_KEY);
    } catch {
      /* storage may be unavailable: the session then lasts until the page closes */
    }
  }

  private async call(path: string, body: object, step: Step): Promise<void> {
    try {
      await firstValueFrom(this.http.post(this.url(path), body));
    } catch (error) {
      throw failure(error, step);
    }
  }

  private url(path: string): string {
    return `${this.config.apiUrl}${path}`;
  }
}

type Step = 'login' | 'register' | 'verify' | 'resend' | 'forgot' | 'reset' | 'google';

/** Firebase's own error codes for Google's window. */
function googleWindowFailure(error: unknown): AuthFailure {
  const code = typeof error === 'object' && error !== null && 'code' in error ? String((error as { code: unknown }).code) : '';
  if (code === 'auth/popup-closed-by-user' || code === 'auth/cancelled-popup-request') {
    return new AuthFailure('google', false, true);
  }
  if (code === 'auth/popup-blocked') return new AuthFailure('googleBlocked');
  if (code === 'auth/unauthorized-domain' || code === 'auth/operation-not-allowed') return new AuthFailure('googleDomain');
  if (code === 'auth/network-request-failed') return new AuthFailure('network');
  return new AuthFailure('google');
}

/** Reduces an API answer to one key. The API's own sentences are English, so the site words it itself. */
export function failure(error: unknown, step: Step): AuthFailure {
  if (!(error instanceof HttpErrorResponse)) return new AuthFailure('failed');
  if (error.status === 0) return new AuthFailure('network');
  if (error.status === 429) return new AuthFailure('tooMany');

  const body = (error.error ?? {}) as { message?: unknown; email_verified?: unknown; errors?: Record<string, unknown> };
  const message = typeof body.message === 'string' ? body.message.toLowerCase() : '';
  const field = (name: string): string => {
    const value = body.errors?.[name];
    return (Array.isArray(value) ? value.join(' ') : typeof value === 'string' ? value : '').toLowerCase();
  };

  if (step === 'login') {
    if (error.status === 403 && body.email_verified === false) return new AuthFailure('badCredentials', true);
    if (error.status === 403) return new AuthFailure('inactive');
    if (error.status === 422) return new AuthFailure('badCredentials');
  }

  if (step === 'google') {
    if (error.status === 503) return new AuthFailure('googleUnavailable');
    if (error.status === 409) return new AuthFailure('googleConflict');
    if (error.status === 403) {
      if (message.includes('inactive')) return new AuthFailure('inactive');
      if (message.includes('verify')) return new AuthFailure('googleVerify');
      return new AuthFailure('googleOwner');
    }
    return new AuthFailure('google');
  }

  if (error.status === 422) {
    const email = field('email');
    const phone = field('phone');
    const password = field('password');
    const code = field('code');
    if (email.includes('wait') || code.includes('wait')) return new AuthFailure('wait');
    if (email.includes('unable to send')) return new AuthFailure('mailFailed');
    if (email.includes('taken')) return new AuthFailure('emailTaken');
    if (phone.includes('taken')) return new AuthFailure('phoneTaken');
    if (phone) return new AuthFailure('phoneInvalid');
    if (password.includes('confirmation')) return new AuthFailure('passwordMismatch');
    if (password) return new AuthFailure('passwordShort');
    if (email) return new AuthFailure('email');
    if (code.includes('expired')) return new AuthFailure('codeExpired');
    if (code.includes('too many')) return new AuthFailure('codeAttempts');
    if (code.includes('no ') && code.includes('found')) return new AuthFailure('codeMissing');
    if (code) return new AuthFailure('codeWrong');
  }
  return new AuthFailure('failed');
}
