import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, forkJoin, map, of, switchMap } from 'rxjs';
import { ApiConfig } from './api-config';
import { PageMeta } from './models';

export interface Page<T> {
  items: T[];
  meta: PageMeta | null;
}

@Injectable({ providedIn: 'root' })
export class ApiService {
  private readonly http = inject(HttpClient);
  private readonly config = inject(ApiConfig);

  page<T>(path: string, page = 1): Observable<Page<T>> {
    return this.http
      .get<unknown>(this.url(path), { params: { page } })
      .pipe(map((body) => readPage<T>(body)));
  }

  all<T>(path: string): Observable<T[]> {
    return this.page<T>(path, 1).pipe(
      switchMap((first) => {
        const last = first.meta?.last_page ?? 1;
        if (last <= 1) return of(first.items);
        const rest = Array.from({ length: last - 1 }, (_, index) => this.page<T>(path, index + 2));
        return forkJoin(rest).pipe(
          map((pages) => pages.reduce((items, entry) => items.concat(entry.items), first.items)),
        );
      }),
    );
  }

  get<T>(path: string): Observable<T> {
    return this.http.get<unknown>(this.url(path)).pipe(map((body) => readOne<T>(body)));
  }

  send<T>(method: 'post' | 'put' | 'patch', path: string, body: unknown): Observable<T> {
    return this.http.request<unknown>(method, this.url(path), { body }).pipe(map((response) => readOne<T>(response)));
  }

  remove(path: string): Observable<void> {
    return this.http.delete(this.url(path)).pipe(map(() => undefined));
  }

  private url(path: string): string {
    return `${this.config.apiUrl}${path}`;
  }
}

export function errorText(error: unknown): string {
  if (!(error instanceof HttpErrorResponse)) return 'تعذر إكمال الطلب.';
  const body = error.error as { message?: string; errors?: Record<string, string[]> } | null;
  const first = body?.errors ? Object.values(body.errors)[0] : undefined;
  if (Array.isArray(first) && first[0]) return first[0];
  if (error.status === 0) return 'تعذر الاتصال بالخادم.';
  if (error.status === 403) return body?.message || 'لا تملك صلاحية لهذا الإجراء.';
  if (error.status === 401) return 'البريد أو كلمة المرور غير صحيحة.';
  if (typeof body?.message === 'string' && body.message !== '') return arabicMessage(body.message);
  return 'تعذر إكمال الطلب.';
}

const MESSAGES: [RegExp, string][] = [
  [/project cannot be deleted because it has testimonials/i, 'لا يمكن حذف المشروع لأن عليه آراء. احذف الآراء أولاً.'],
  [/category cannot be deleted because it has projects/i, 'لا يمكن حذف التصنيف لأن فيه مشاريع. انقل المشاريع أو احذفها أولاً.'],
  [/service cannot be deleted because it is assigned to projects/i, 'لا يمكن حذف الخدمة لأنها مرتبطة بمشاريع. أزلها من المشاريع أولاً.'],
  [/email has already submitted a testimonial/i, 'هذا البريد أرسل رأياً من قبل.'],
];

function arabicMessage(message: string): string {
  return MESSAGES.find(([pattern]) => pattern.test(message))?.[1] ?? message;
}

function readPage<T>(body: unknown): Page<T> {
  const record = asRecord(body);
  const data = record?.['data'];
  const meta = asRecord(record?.['meta']);
  return {
    items: asItems<T>(data),
    meta: meta
      ? {
          current_page: Number(meta['current_page'] ?? 1),
          last_page: Number(meta['last_page'] ?? 1),
          per_page: Number(meta['per_page'] ?? 15),
          total: Number(meta['total'] ?? 0),
        }
      : null,
  };
}

function readOne<T>(body: unknown): T {
  const record = asRecord(body);
  if (record && 'data' in record) return record['data'] as T;
  return body as T;
}

function asItems<T>(data: unknown): T[] {
  if (Array.isArray(data)) return data as T[];
  const nested = asRecord(data);
  if (nested && Array.isArray(nested['data'])) return nested['data'] as T[];
  return [];
}

function asRecord(value: unknown): Record<string, unknown> | null {
  return value !== null && typeof value === 'object' ? value as Record<string, unknown> : null;
}
