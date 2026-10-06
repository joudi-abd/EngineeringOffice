import { Component, OnInit, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { ApiService, errorText } from '../../core/api.service';
import { ConfirmService } from '../../core/confirm.service';
import { Project, ProjectCategory, ProjectImage, Service } from '../../core/models';
import { recordSlug } from '../../core/slug';

@Component({
  selector: 'app-project-editor',
  imports: [ReactiveFormsModule, RouterLink],
  templateUrl: './project-editor.component.html',
})
export class ProjectEditorComponent implements OnInit {
  private readonly api = inject(ApiService);
  private readonly confirm = inject(ConfirmService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly formBuilder = inject(FormBuilder);

  protected readonly error = signal('');
  protected readonly note = signal('');
  protected readonly busy = signal(false);
  protected readonly id = signal<number | null>(null);
  protected readonly categories = signal<ProjectCategory[]>([]);
  protected readonly services = signal<Service[]>([]);
  protected readonly images = signal<ProjectImage[]>([]);
  protected readonly coverName = signal('');
  protected readonly galleryName = signal('');
  private cover: File | null = null;
  private gallery: File | null = null;
  private savedSlug = '';

  protected readonly form = this.formBuilder.nonNullable.group({
    category_id: ['', Validators.required],
    title: ['', Validators.required],
    short_description: [''],
    description: [''],
    location: [''],
    area: [''],
    year: [''],
    status: ['completed' as Project['status']],
    is_featured: [false],
    published_at: [''],
    alt_text: [''],
    service_ids: [[] as number[]],
  });

  ngOnInit(): void {
    this.api.all<ProjectCategory>('/admin/categories').subscribe({
      next: (items) => this.categories.set(items),
      error: (error: unknown) => this.error.set(errorText(error)),
    });
    this.api.all<Service>('/admin/services').subscribe({
      next: (items) => this.services.set(items),
      error: () => undefined,
    });
    const raw = this.route.snapshot.paramMap.get('id');
    if (!raw || raw === 'new') return;
    this.load(Number(raw));
  }

  protected toggleService(id: number, checked: boolean): void {
    const current = this.form.controls.service_ids.value;
    this.form.controls.service_ids.setValue(
      checked ? [...current, id] : current.filter((item) => item !== id),
    );
  }

  protected chosen(id: number): boolean {
    return this.form.controls.service_ids.value.includes(id);
  }

  protected onCover(event: Event): void {
    const file = (event.target as HTMLInputElement).files?.[0] ?? null;
    this.cover = file;
    this.coverName.set(file?.name ?? '');
  }

  protected onGallery(event: Event): void {
    const file = (event.target as HTMLInputElement).files?.[0] ?? null;
    this.gallery = file;
    this.galleryName.set(file?.name ?? '');
  }

  protected save(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      this.error.set('التصنيف والعنوان مطلوبان.');
      return;
    }
    this.busy.set(true);
    this.error.set('');
    const value = this.form.getRawValue();
    const title = value.title.trim();
    const body: Record<string, unknown> = {
      category_id: Number(value.category_id),
      title,
      slug: recordSlug(title, this.savedSlug),
      short_description: value.short_description.trim() || null,
      description: value.description.trim() || null,
      location: value.location.trim() || null,
      area: value.area === '' ? null : Number(value.area),
      year: value.year === '' ? null : Number(value.year),
      status: value.status,
      is_featured: value.is_featured,
      published_at: value.published_at || null,
      service_ids: value.service_ids,
    };
    const payload = this.cover ? this.withFile(body, 'cover_image', this.cover) : body;
    const id = this.id();
    const request = id
      ? this.api.send<Project>('put', `/admin/projects/${id}`, payload)
      : this.api.send<Project>('post', '/admin/projects', payload);
    request.subscribe({
      next: (project) => {
        this.busy.set(false);
        this.cover = null;
        this.coverName.set('');
        if (!id && project?.id) {
          void this.router.navigate(['/projects', project.id]);
          return;
        }
        this.note.set('تم حفظ المشروع.');
        if (id) this.load(id);
      },
      error: (error: unknown) => {
        this.busy.set(false);
        this.error.set(errorText(error));
      },
    });
  }

  protected uploadImage(): void {
    const id = this.id();
    if (!id || !this.gallery) {
      this.error.set('اختر صورة للمشروع.');
      return;
    }
    const form = new FormData();
    form.append('image', this.gallery);
    const alt = this.form.controls.alt_text.value.trim();
    if (alt) form.append('alt_text', alt);
    this.api.send<ProjectImage>('post', `/admin/projects/${id}/images`, form).subscribe({
      next: () => {
        this.gallery = null;
        this.galleryName.set('');
        this.form.controls.alt_text.setValue('');
        this.load(id);
      },
      error: (error: unknown) => this.error.set(errorText(error)),
    });
  }

  protected removeImage(image: ProjectImage): void {
    const id = this.id();
    if (!id) return;
    void this.confirm.ask('حذف هذه الصورة؟').then((accepted) => {
      if (!accepted) return;
      this.deleteImage(id, image.id);
    });
  }

  private deleteImage(projectId: number, imageId: number): void {
    this.api.remove(`/admin/projects/${projectId}/images/${imageId}`).subscribe({
      next: () => this.load(projectId),
      error: (error: unknown) => this.error.set(errorText(error)),
    });
  }

  private load(id: number): void {
    this.id.set(id);
    this.api.get<Project>(`/admin/projects/${id}`).subscribe({
      next: (item) => {
        this.images.set(item.images ?? []);
        this.savedSlug = item.slug;
        this.form.patchValue({
          category_id: item.category?.id ? String(item.category.id) : '',
          title: item.title,
          short_description: item.short_description ?? '',
          description: item.description ?? '',
          location: item.location ?? '',
          area: item.area == null ? '' : String(item.area),
          year: item.year == null ? '' : String(item.year),
          status: item.status,
          is_featured: item.is_featured,
          published_at: item.published_at ? item.published_at.slice(0, 10) : '',
          service_ids: (item.services ?? []).map((service) => service.id),
        });
      },
      error: (error: unknown) => this.error.set(errorText(error)),
    });
  }

  private withFile(body: Record<string, unknown>, key: string, file: File): FormData {
    const form = new FormData();
    for (const [name, value] of Object.entries(body)) {
      if (value == null) continue;
      if (Array.isArray(value)) {
        value.forEach((item) => form.append(`${name}[]`, String(item)));
      } else if (typeof value === 'boolean') {
        form.append(name, value ? '1' : '0');
      } else {
        form.append(name, String(value));
      }
    }
    form.append(key, file);
    return form;
  }
}
