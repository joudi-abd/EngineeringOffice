import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Injectable, computed, inject, signal } from '@angular/core';
import { Observable, catchError, forkJoin, map, of } from 'rxjs';
import { ApiConfig } from './api-config';
import { Translator } from './translator.service';
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

  private readonly tr = inject(Translator);

  readonly ready = signal(false);

  private readonly rawSettings = signal<Setting[]>([]);
  private readonly rawServices = signal<Service[]>([]);
  private readonly rawProjects = signal<Project[]>([]);
  private readonly rawCategories = signal<ProjectCategory[]>([]);
  private readonly rawTeam = signal<TeamMember[]>([]);

  /** Everything below is shown in the current site language (see Translator). */
  readonly settings = computed(() =>
    this.rawSettings().map((item) => (RAW_SETTINGS.has(item.key) ? item : { ...item, value: this.tr.maybe(item.value) })),
  );
  readonly services = computed(() => this.rawServices().map((item) => this.localizeService(item)));
  readonly projects = computed(() => this.rawProjects().map((item) => this.localizeProject(item)));
  readonly categories = computed(() => this.rawCategories().map((item) => this.localizeCategory(item)));
  readonly team = computed(() => this.rawTeam().map((item) => this.localizeMember(item)));

  load(): Observable<void> {
    return forkJoin({
      settings: this.list<Setting>('/settings'),
      services: this.list<Service>('/services'),
      projects: this.list<Project>('/projects'),
      categories: this.list<ProjectCategory>('/categories'),
      team: this.list<TeamMember>('/team-members'),
    }).pipe(
      map((data) => {
        this.rawSettings.set(data.settings);
        this.rawServices.set(data.services.filter((item) => truthy(item.is_active)));
        this.rawProjects.set(data.projects.map((item) => normalizeProject(item)));
        this.rawCategories.set(data.categories.filter((item) => truthy(item.is_active)));
        this.rawTeam.set(data.team.filter((item) => truthy(item.is_active)));
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

  /** Logo uploaded in the dashboard; empty when none, so the built-in brand artwork is used. */
  readonly logo = computed(() => this.media(this.setting('logo')));

  /** Company name from the dashboard (never translated: it is a brand). */
  readonly companyName = computed(() => this.setting('company_name'));

  /** Social accounts entered in the dashboard. Accepts full links or handles; anything else is hidden. */
  readonly social = computed(() =>
    [
      { key: 'facebook', label: 'Facebook', href: socialLink(this.setting('facebook'), 'https://www.facebook.com/') },
      { key: 'instagram', label: 'Instagram', href: socialLink(this.setting('instagram'), 'https://www.instagram.com/') },
    ].filter((item) => item.href),
  );

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

  localizeProject(project: Project): Project {
    const t = this.tr;
    return {
      ...project,
      title: t.text(project.title),
      short_description: t.maybe(project.short_description),
      description: t.maybe(project.description),
      location: t.maybe(project.location),
      category: project.category ? this.localizeCategory(project.category) : null,
      services: project.services.map((item) => this.localizeService(item)),
      images: project.images.map((image) => ({ ...image, alt_text: t.maybe(image.alt_text) })),
      videos: project.videos.map((video) => ({ ...video, title: t.maybe(video.title) })),
    };
  }

  localizeReview(review: Testimonial): Testimonial {
    return { ...review, client_name: this.tr.name(review.client_name), content: this.tr.text(review.content) };
  }

  private localizeCategory(category: ProjectCategory): ProjectCategory {
    return { ...category, name: this.tr.text(category.name), description: this.tr.maybe(category.description) };
  }

  private localizeService(service: Service): Service {
    return {
      ...service,
      name: this.tr.text(service.name),
      short_description: this.tr.maybe(service.short_description),
      description: this.tr.maybe(service.description),
    };
  }

  private localizeMember(member: TeamMember): TeamMember {
    return {
      ...member,
      name: this.tr.name(member.name),
      job_title: this.tr.text(member.job_title),
      bio: this.tr.maybe(member.bio),
    };
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

/** Settings whose values are identifiers (numbers, links) and must never be translated. */
const RAW_SETTINGS = new Set(['phone', 'email', 'whatsapp', 'logo', 'facebook', 'instagram', 'company_name']);

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

function socialLink(value: string, base: string): string {
  const text = value.trim();
  if (!text) return '';
  if (/^https?:\/\//i.test(text)) return text;
  if (/^([a-z0-9-]+\.)+[a-z]{2,}(\/|$)/i.test(text)) return `https://${text}`;
  const handle = text.replace(/^@/, '');
  return /^[A-Za-z0-9._-]{2,60}$/.test(handle) ? `${base}${handle}` : '';
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
    videos: raw.videos ?? [],
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
