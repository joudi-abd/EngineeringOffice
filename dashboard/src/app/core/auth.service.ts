import { HttpClient } from '@angular/common/http';
import { Injectable, inject, signal } from '@angular/core';
import { Observable, tap } from 'rxjs';
import { ApiConfig } from './api-config';
import { AuthUser } from './models';

const TOKEN_KEY = 'ufuq-dashboard-token';

interface LoginResponse {
  access_token: string;
  user: AuthUser;
}

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly http = inject(HttpClient);
  private readonly config = inject(ApiConfig);

  readonly token = signal<string | null>(this.readToken());
  readonly user = signal<AuthUser | null>(null);

  login(email: string, password: string): Observable<LoginResponse> {
    return this.http.post<LoginResponse>(`${this.config.apiUrl}/auth/login`, { email, password }).pipe(
      tap((response) => {
        this.persist(response.access_token);
        this.user.set(response.user);
      }),
    );
  }

  me(): Observable<AuthUser> {
    return this.http.get<AuthUser>(`${this.config.apiUrl}/auth/me`).pipe(
      tap((user) => this.user.set(user)),
    );
  }

  logout(): Observable<{ message: string }> {
    return this.http.post<{ message: string }>(`${this.config.apiUrl}/auth/logout`, {}).pipe(
      tap(() => this.clear()),
    );
  }

  clear(): void {
    this.token.set(null);
    this.user.set(null);
    try {
      localStorage.removeItem(TOKEN_KEY);
    } catch {
      /* storage may be unavailable */
    }
  }

  private persist(token: string): void {
    this.token.set(token);
    try {
      localStorage.setItem(TOKEN_KEY, token);
    } catch {
      /* storage may be unavailable */
    }
  }

  private readToken(): string | null {
    try {
      return localStorage.getItem(TOKEN_KEY);
    } catch {
      return null;
    }
  }
}
