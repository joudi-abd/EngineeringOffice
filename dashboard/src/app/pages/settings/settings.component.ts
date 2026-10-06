import { Component, OnInit, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { forkJoin } from 'rxjs';
import { ApiConfig } from '../../core/api-config';
import { ApiService, errorText } from '../../core/api.service';
import { Setting } from '../../core/models';

const DAY_OPTIONS = ['الأحد – الخميس', 'الإثنين – الجمعة', 'السبت – الخميس', 'كل الأيام'];

@Component({
  selector: 'app-settings',
  imports: [FormsModule],
  templateUrl: './settings.component.html',
})
export class SettingsComponent implements OnInit {
  private readonly api = inject(ApiService);
  private readonly config = inject(ApiConfig);

  protected readonly dayOptions = DAY_OPTIONS;
  protected readonly values = signal<Record<string, string>>({});
  protected readonly days = signal(DAY_OPTIONS[0]);
  protected readonly customDays = signal('');
  protected readonly from = signal('09:00');
  protected readonly to = signal('17:00');
  protected readonly showHours = signal(false);
  protected readonly error = signal('');
  protected readonly saved = signal('');
  protected readonly ready = signal(false);
  protected readonly busy = signal(false);
  protected readonly logoPreview = signal('');

  private types = new Map<string, string>();
  private logoFile: File | null = null;
  private logoObjectUrl = '';

  ngOnInit(): void {
    this.api.page<Setting>('/admin/settings').subscribe({
      next: (page) => {
        const next: Record<string, string> = {};
        for (const item of page.items) {
          next[item.key] = item.value ?? '';
          this.types.set(item.key, item.type || 'string');
        }
        this.values.set(next);
        this.readHours(next['hours'] ?? '');
        this.logoPreview.set(this.media(next['logo'] ?? ''));
        this.ready.set(true);
      },
      error: (error: unknown) => this.error.set(errorText(error)),
    });
  }

  protected value(key: string): string {
    return this.values()[key] ?? '';
  }

  protected setValue(key: string, event: Event): void {
    const value = (event.target as HTMLInputElement | HTMLTextAreaElement).value;
    this.values.update((current) => ({ ...current, [key]: value }));
    this.saved.set('');
  }

  protected setDays(event: Event): void {
    this.days.set((event.target as HTMLSelectElement).value);
    this.showHours.set(true);
    this.saved.set('');
  }

  protected setCustomDays(event: Event): void {
    this.customDays.set((event.target as HTMLInputElement).value);
    this.showHours.set(true);
    this.saved.set('');
  }

  protected setTime(field: 'from' | 'to', event: Event): void {
    const value = (event.target as HTMLInputElement).value;
    if (field === 'from') this.from.set(value);
    else this.to.set(value);
    this.showHours.set(true);
    this.saved.set('');
  }

  protected hoursLabel(): string {
    const days = this.days() === 'custom' ? this.customDays().trim() : this.days();
    if (!days) return '';
    if (!this.from() || !this.to()) return days;
    return `${days}، ${this.from()} – ${this.to()}`;
  }

  protected chooseLogo(event: Event): void {
    const file = (event.target as HTMLInputElement).files?.[0];
    if (!file) return;
    if (this.logoObjectUrl) URL.revokeObjectURL(this.logoObjectUrl);
    this.logoFile = file;
    this.logoObjectUrl = URL.createObjectURL(file);
    this.logoPreview.set(this.logoObjectUrl);
    this.saved.set('');
  }

  protected clearLogo(input: HTMLInputElement): void {
    if (this.logoObjectUrl) URL.revokeObjectURL(this.logoObjectUrl);
    this.logoFile = null;
    this.logoObjectUrl = '';
    this.logoPreview.set('');
    input.value = '';
    this.values.update((current) => ({ ...current, logo: '' }));
    this.saved.set('');
  }

  protected save(): void {
    this.busy.set(true);
    this.error.set('');
    this.saved.set('');
    const current: Record<string, string> = { ...this.values() };
    if (this.showHours()) current['hours'] = this.hoursLabel();
    const calls = Object.entries(current).map(([key, value]) => {
      if (key === 'logo' && this.logoFile) {
        const form = new FormData();
        form.append('value', this.logoFile);
        form.append('type', 'string');
        return this.api.send<Setting>('put', '/admin/settings/logo', form);
      }
      return this.api.send<Setting>('put', `/admin/settings/${encodeURIComponent(key)}`, {
        value,
        type: this.types.get(key) || 'string',
      });
    });

    forkJoin(calls).subscribe({
      next: (saved) => {
        const next = { ...current };
        for (const item of saved) {
          if (item?.key) next[item.key] = item.value ?? '';
        }
        this.values.set(next);
        this.logoFile = null;
        if (this.logoObjectUrl) URL.revokeObjectURL(this.logoObjectUrl);
        this.logoObjectUrl = '';
        this.logoPreview.set(this.media(next['logo'] ?? ''));
        this.busy.set(false);
        this.saved.set('تم حفظ الإعدادات.');
      },
      error: (error: unknown) => {
        this.busy.set(false);
        this.error.set(errorText(error));
      },
    });
  }

  private readHours(value: string): void {
    const match = value.match(/^(.+)،\s*(\d{1,2}:\d{2})\s*[–-]\s*(\d{1,2}:\d{2})$/);
    if (!match) {
      if (value) {
        this.days.set('custom');
        this.customDays.set(value);
        this.showHours.set(true);
      }
      return;
    }
    this.showHours.set(true);
    const days = match[1].trim();
    this.from.set(match[2].padStart(5, '0'));
    this.to.set(match[3].padStart(5, '0'));
    if (DAY_OPTIONS.includes(days)) {
      this.days.set(days);
      return;
    }
    this.days.set('custom');
    this.customDays.set(days);
  }

  private media(value: string): string {
    if (!value) return '';
    if (/^https?:\/\//i.test(value)) return value;
    const origin = new URL(this.config.apiUrl).origin;
    if (value.startsWith('/')) return `${origin}${value}`;
    return `${origin}/storage/${value.replace(/^\/+/, '')}`;
  }
}
