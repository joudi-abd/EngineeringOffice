import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Injectable, inject, signal } from '@angular/core';
import { Observable, catchError, forkJoin, map, of } from 'rxjs';
import { ApiConfig } from './api-config';
import {
  ContactMessage,
  Project,
  ProjectCategory,
  Service,
  Setting,
  TeamMember,
  Testimonial,
} from './site-content';

@Injectable({ providedIn: 'root' })
export class SiteApi {
  private readonly http = inject(HttpClient);
  private readonly config = inject(ApiConfig);

  readonly ready = signal(false);
  readonly settings = signal<Setting[]>([]);
  readonly services = signal<Service[]>([]);
  readonly projects = signal<Project[]>([]);
  readonly categories = signal<ProjectCategory[]>([]);
  readonly team = signal<TeamMember[]>([]);

  load(): Observable<void> {
    return forkJoin({
      settings: this.list<Setting>('/settings'),
      services: this.list<Service>('/services'),
      projects: this.list<Project>('/projects'),
      categories: this.list<ProjectCategory>('/categories'),
      team: this.list<TeamMember>('/team-members'),
    }).pipe(
      map((data) => {
        this.settings.set(data.settings);
        this.services.set(data.services.filter((item) => truthy(item.is_active)));
        this.projects.set(data.projects.map((item) => normalizeProject(item)));
        this.categories.set(data.categories.filter((item) => truthy(item.is_active)));
        this.team.set(data.team.filter((item) => truthy(item.is_active)));
        this.ready.set(true);
      }),
      catchError(() => {
        this.ready.set(true);
        return of(undefined);
      }),
    );
  }

  setting(key: string): string {
    return this.settings().find((item) => item.key === key)?.value?.trim() ?? '';
  }

  media(value: string | null | undefined): string {
    if (!value || value.startsWith('/tmp/')) return '';
    const origin = this.config.origin();
    const storage = storagePath(value);
    if (storage) return `${origin}/storage/${storage}`;
    if (/^https?:\/\//i.test(value)) return value;
    if (value.startsWith('/images/') || value.startsWith('images/')) {
      return value.startsWith('/') ? value : `/${value}`;
    }
    if (value.startsWith('/')) return `${origin}${value}`;
    return `${origin}/storage/${value.replace(/^\/+/, '')}`;
  }

  project(slug: string): Observable<Project | null> {
    if (!slug) return of(null);
    return this.http.get<unknown>(this.url(`/projects/${encodeURIComponent(slug)}`)).pipe(
      map((body) => {
        const item = unwrapOne<Project>(body);
        return item ? normalizeProject(item) : null;
      }),
      catchError(() => of(null)),
    );
  }

  reviews(projectId: number): Observable<Testimonial[]> {
    return this.list<Testimonial>(`/projects/${projectId}/testimonials`);
  }

  sendReview(projectId: number, body: ReviewDraft): Observable<void> {
    return this.http.post(this.url(`/projects/${projectId}/testimonials`), body).pipe(map(() => undefined));
  }

  sendMessage(body: Omit<ContactMessage, 'status'>): Observable<void> {
    return this.http.post(this.url('/contact-messages'), body).pipe(map(() => undefined));
  }

  private list<T>(path: string): Observable<T[]> {
    return this.http.get<unknown>(this.url(path)).pipe(
      map((body) => unwrap<T>(body)),
      catchError(() => of([])),
    );
  }

  private url(path: string): string {
    return `${this.config.apiUrl}${path}`;
  }
}

export interface ReviewDraft {
  client_name: string;
  client_email: string;
  content: string;
  rating: number;
}

export function httpStatus(error: unknown): number {
  return error instanceof HttpErrorResponse ? error.status : 0;
}

function storagePath(value: string): string {
  const path = /^https?:\/\//i.test(value)
    ? (() => {
        try {
          return new URL(value).pathname;
        } catch {
          return '';
        }
      })()
    : value;
  const marker = '/storage/';
  const at = path.indexOf(marker);
  if (at === -1) return '';
  return path.slice(at + marker.length).replace(/^\/+/, '');
}

function truthy(value: boolean | number | string | null | undefined): boolean {
  return value === true || value === 1 || value === '1';
}

function normalizeProject(raw: Project): Project {
  return {
    ...raw,
    area: raw.area == null || raw.area === '' ? null : Number(raw.area),
    year: raw.year == null || raw.year === '' ? null : Number(raw.year),
    is_featured: truthy(raw.is_featured),
    category: raw.category ?? null,
    images: raw.images ?? [],
    services: (raw.services ?? []).filter((item) => truthy(item.is_active)),
  };
}

function unwrap<T>(body: unknown): T[] {
  const data = envelope(body);
  return Array.isArray(data) ? data : [];
}

function unwrapOne<T>(body: unknown): T | null {
  const data = envelope(body);
  return data && typeof data === 'object' && !Array.isArray(data) ? data as T : null;
}

function envelope(body: unknown): unknown {
  if (!body || typeof body !== 'object' || !('data' in body)) return body;
  const data = (body as { data: unknown }).data;
  if (data && typeof data === 'object' && !Array.isArray(data) && 'data' in data) {
    return (data as { data: unknown }).data;
  }
  return data;
}
