import { Component, OnInit, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { ApiService, errorText } from '../../core/api.service';
import { Service } from '../../core/models';
import { recordSlug } from '../../core/slug';

@Component({
  selector: 'app-service-editor',
  imports: [ReactiveFormsModule, RouterLink],
  templateUrl: './service-editor.component.html',
})
export class ServiceEditorComponent implements OnInit {
  private readonly api = inject(ApiService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly formBuilder = inject(FormBuilder);
  private image: File | null = null;

  protected readonly error = signal('');
  protected readonly busy = signal(false);
  protected readonly id = signal<number | null>(null);
  protected readonly fileName = signal('');
  protected readonly imageUrl = signal<string | null>(null);
  private savedSlug = '';
  protected readonly form = this.formBuilder.nonNullable.group({
    name: ['', Validators.required],
    short_description: [''],
    description: [''],
    icon: [''],
    is_active: [true],
  });

  ngOnInit(): void {
    const raw = this.route.snapshot.paramMap.get('id');
    if (!raw || raw === 'new') return;
    const id = Number(raw);
    this.id.set(id);
    this.api.get<Service>(`/admin/services/${id}`).subscribe({
      next: (item) => {
        this.imageUrl.set(item.image_url);
        this.savedSlug = item.slug;
        this.form.patchValue({
          name: item.name,
          short_description: item.short_description ?? '',
          description: item.description ?? '',
          icon: item.icon ?? '',
          is_active: item.is_active,
        });
      },
      error: (error: unknown) => this.error.set(errorText(error)),
    });
  }

  protected onFile(event: Event): void {
    const file = (event.target as HTMLInputElement).files?.[0] ?? null;
    this.image = file;
    this.fileName.set(file?.name ?? '');
  }

  protected save(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      this.error.set('الاسم مطلوب.');
      return;
    }
    this.busy.set(true);
    const value = this.form.getRawValue();
    const name = value.name.trim();
    const body: Record<string, unknown> = {
      name,
      slug: recordSlug(name, this.savedSlug),
      short_description: value.short_description.trim() || null,
      description: value.description.trim() || null,
      icon: value.icon.trim() || null,
      is_active: value.is_active,
    };
    const payload = this.image ? this.withFile(body, this.image) : body;
    const id = this.id();
    const request = id
      ? this.api.send('put', `/admin/services/${id}`, payload)
      : this.api.send('post', '/admin/services', payload);
    request.subscribe({
      next: () => void this.router.navigate(['/services']),
      error: (error: unknown) => {
        this.busy.set(false);
        this.error.set(errorText(error));
      },
    });
  }

  private withFile(body: Record<string, unknown>, file: File): FormData {
    const form = new FormData();
    for (const [name, value] of Object.entries(body)) {
      if (value == null) continue;
      form.append(name, typeof value === 'boolean' ? (value ? '1' : '0') : String(value));
    }
    form.append('image', file);
    return form;
  }
}
