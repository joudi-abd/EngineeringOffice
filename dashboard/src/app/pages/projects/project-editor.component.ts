import { Location } from '@angular/common';
import { Component, OnDestroy, OnInit, computed, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { Observable, firstValueFrom } from 'rxjs';
import { ApiService, errorText } from '../../core/api.service';
import { Project, ProjectCategory, ProjectImage, ProjectVideo, Service } from '../../core/models';
import { recordSlug } from '../../core/slug';

const MAX_IMAGE = 5 * 1024 * 1024;
const MAX_VIDEO = 200 * 1024 * 1024;
const VIDEO_TYPES = ['video/mp4', 'video/webm', 'video/quicktime'];

interface QueuedImage {
  key: number;
  file: File;
  preview: string;
}

interface QueuedVideo {
  key: number;
  file: File | null;
  url: string;
  label: string;
}

import { SelectComponent, SelectOption } from '../../layout/select.component';

@Component({
  selector: 'app-project-editor',
  imports: [ReactiveFormsModule, RouterLink, SelectComponent],
  templateUrl: './project-editor.component.html',
})
export class ProjectEditorComponent implements OnInit, OnDestroy {
  private readonly api = inject(ApiService);
  private readonly route = inject(ActivatedRoute);
  private readonly location = inject(Location);
  private readonly formBuilder = inject(FormBuilder);

  protected readonly statusOptions: SelectOption[] = [
    { value: 'planning', label: 'تخطيط' },
    { value: 'in_progress', label: 'قيد التنفيذ' },
    { value: 'completed', label: 'مكتمل' },
  ];
  protected readonly categoryOptions = computed<SelectOption[]>(() =>
    this.categories().map((category) => ({ value: String(category.id), label: category.name })),
  );
  protected readonly error = signal('');
  protected readonly note = signal('');
  protected readonly busy = signal(false);
  protected readonly progress = signal('');
  protected readonly id = signal<number | null>(null);
  protected readonly categories = signal<ProjectCategory[]>([]);
  protected readonly services = signal<Service[]>([]);

  protected readonly coverPreview = signal('');
  protected readonly coverIsNew = signal(false);

  protected readonly images = signal<ProjectImage[]>([]);
  protected readonly queuedImages = signal<QueuedImage[]>([]);
  protected readonly removedImages = signal<number[]>([]);
  /** Thumbnails ticked for a bulk action: "s<id>" for saved images, "q<key>" for images waiting to upload. */
  protected readonly selected = signal<string[]>([]);
  protected readonly dragging = signal(false);

  protected readonly videos = signal<ProjectVideo[]>([]);
  protected readonly queuedVideos = signal<QueuedVideo[]>([]);
  protected readonly removedVideos = signal<number[]>([]);
  protected readonly videoLink = signal('');

  private cover: File | null = null;
  private savedCover = '';
  private savedSlug = '';
  private counter = 0;

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

  ngOnDestroy(): void {
    this.releaseCover();
    this.queuedImages().forEach((item) => URL.revokeObjectURL(item.preview));
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
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0] ?? null;
    input.value = '';
    if (!file) return;
    if (!file.type.startsWith('image/')) return this.error.set('غلاف المشروع يجب أن يكون صورة.');
    if (file.size > MAX_IMAGE) return this.error.set(`حجم الصورة «${file.name}» أكبر من 5 ميغابايت.`);
    this.error.set('');
    this.releaseCover();
    this.cover = file;
    this.coverIsNew.set(true);
    this.coverPreview.set(URL.createObjectURL(file));
  }

  protected clearNewCover(): void {
    this.releaseCover();
    this.cover = null;
    this.coverIsNew.set(false);
    this.coverPreview.set(this.savedCover);
  }

  protected onImages(event: Event): void {
    const input = event.target as HTMLInputElement;
    const files = Array.from(input.files ?? []);
    input.value = '';
    this.addImages(files);
  }

  protected onDropImages(event: DragEvent): void {
    event.preventDefault();
    this.dragging.set(false);
    this.addImages(Array.from(event.dataTransfer?.files ?? []));
  }

  protected onDragOver(event: DragEvent): void {
    event.preventDefault();
    this.dragging.set(true);
  }

  private addImages(files: File[]): void {
    const added: QueuedImage[] = [];
    const rejected: string[] = [];
    for (const file of files) {
      if (!file.type.startsWith('image/') || file.size > MAX_IMAGE) {
        rejected.push(file.name);
        continue;
      }
      added.push({ key: ++this.counter, file, preview: URL.createObjectURL(file) });
    }
    this.queuedImages.update((items) => [...items, ...added]);
    this.error.set(rejected.length ? `لم تُضَف هذه الملفات (صورة حتى 5 ميغابايت): ${rejected.join('، ')}` : '');
  }

  protected isSelected(key: string): boolean {
    return this.selected().includes(key);
  }

  protected toggleSelected(key: string): void {
    this.selected.update((keys) => (keys.includes(key) ? keys.filter((k) => k !== key) : [...keys, key]));
  }

  protected selectAllImages(): void {
    this.selected.set([
      ...this.images().filter((image) => !this.removedImages().includes(image.id)).map((image) => `s${image.id}`),
      ...this.queuedImages().map((item) => `q${item.key}`),
    ]);
  }

  protected clearSelection(): void {
    this.selected.set([]);
  }

  /** Deletes every ticked image at once: saved ones are removed on save, queued ones are dropped now. */
  protected removeSelected(): void {
    const keys = new Set(this.selected());
    const savedIds = this.images().filter((image) => keys.has(`s${image.id}`)).map((image) => image.id);
    this.removedImages.update((ids) => [...ids, ...savedIds.filter((id) => !ids.includes(id))]);
    this.queuedImages()
      .filter((item) => keys.has(`q${item.key}`))
      .forEach((item) => this.dropQueuedImage(item));
    this.selected.set([]);
  }

  protected dropQueuedImage(item: QueuedImage): void {
    this.selected.update((keys) => keys.filter((key) => key !== `q${item.key}`));
    URL.revokeObjectURL(item.preview);
    this.queuedImages.update((items) => items.filter((entry) => entry.key !== item.key));
  }

  protected toggleImage(image: ProjectImage): void {
    this.removedImages.update((ids) =>
      ids.includes(image.id) ? ids.filter((id) => id !== image.id) : [...ids, image.id],
    );
  }

  protected onVideos(event: Event): void {
    const input = event.target as HTMLInputElement;
    const files = Array.from(input.files ?? []);
    input.value = '';
    const added: QueuedVideo[] = [];
    const rejected: string[] = [];
    for (const file of files) {
      if (!VIDEO_TYPES.includes(file.type) || file.size > MAX_VIDEO) {
        rejected.push(file.name);
        continue;
      }
      added.push({ key: ++this.counter, file, url: '', label: file.name });
    }
    this.queuedVideos.update((items) => [...items, ...added]);
    this.error.set(rejected.length ? `لم تُضَف هذه الملفات (MP4 أو WebM أو MOV حتى 200 ميغابايت): ${rejected.join('، ')}` : '');
  }

  protected setVideoLink(event: Event): void {
    this.videoLink.set((event.target as HTMLInputElement).value);
  }

  protected addVideoLink(): boolean {
    const raw = this.videoLink().trim();
    if (!raw) return true;
    if (!/^https?:\/\/\S+$/i.test(raw)) {
      this.error.set('رابط الفيديو غير صالح. يجب أن يبدأ بـ http أو https.');
      return false;
    }
    this.queuedVideos.update((items) => [...items, { key: ++this.counter, file: null, url: raw, label: raw }]);
    this.videoLink.set('');
    this.error.set('');
    return true;
  }

  protected dropQueuedVideo(item: QueuedVideo): void {
    this.queuedVideos.update((items) => items.filter((entry) => entry.key !== item.key));
  }

  protected toggleVideo(video: ProjectVideo): void {
    this.removedVideos.update((ids) =>
      ids.includes(video.id) ? ids.filter((id) => id !== video.id) : [...ids, video.id],
    );
  }

  protected videoName(video: ProjectVideo, index: number): string {
    return video.title || video.external_url || `فيديو ${index + 1}`;
  }

  protected async save(): Promise<void> {
    if (this.busy()) return;
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      this.error.set('التصنيف والعنوان مطلوبان.');
      return;
    }
    if (!this.addVideoLink()) return;

    this.busy.set(true);
    this.error.set('');
    this.note.set('');
    const failures: string[] = [];

    try {
      this.progress.set('جارٍ حفظ بيانات المشروع…');
      const saved = await this.saveProject();
      this.id.set(saved.id);
      this.savedSlug = saved.slug;

      for (const imageId of this.removedImages()) {
        await this.attempt(failures, 'حذف صورة', () => this.api.remove(`/admin/projects/${saved.id}/images/${imageId}`));
      }
      for (const videoId of this.removedVideos()) {
        await this.attempt(failures, 'حذف فيديو', () => this.api.remove(`/admin/projects/${saved.id}/videos/${videoId}`));
      }

      const images = this.queuedImages();
      for (const [index, item] of images.entries()) {
        this.progress.set(`رفع الصور ${index + 1} من ${images.length}…`);
        const body = new FormData();
        body.append('image', item.file);
        const ok = await this.attempt(failures, item.file.name, () =>
          this.api.send<ProjectImage>('post', `/admin/projects/${saved.id}/images`, body),
        );
        if (ok) this.dropQueuedImage(item);
      }

      const videos = this.queuedVideos();
      for (const [index, item] of videos.entries()) {
        this.progress.set(`رفع الفيديو ${index + 1} من ${videos.length}…`);
        const body = new FormData();
        if (item.file) body.append('video', item.file);
        else body.append('external_url', item.url);
        const ok = await this.attempt(failures, item.label, () =>
          this.api.send<ProjectVideo>('post', `/admin/projects/${saved.id}/videos`, body),
        );
        if (ok) this.dropQueuedVideo(item);
      }

      this.location.replaceState(`/projects/${saved.id}`);
      await this.reload(saved.id);

      if (failures.length) {
        this.error.set(`حُفظ المشروع لكن تعذّر: ${failures.join(' — ')}. أعد المحاولة بالضغط على حفظ.`);
      } else {
        this.note.set('تم حفظ المشروع.');
      }
    } catch (error: unknown) {
      this.error.set(errorText(error));
    } finally {
      this.busy.set(false);
      this.progress.set('');
    }
  }

  private async saveProject(): Promise<Project> {
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

    const id = this.id();
    if (!id) {
      const payload = this.cover ? this.withFile(body, 'cover_image', this.cover) : body;
      const created = await firstValueFrom(this.api.send<Project>('post', '/admin/projects', payload));
      this.cover = null;
      this.coverIsNew.set(false);
      return created;
    }

    const updated = await firstValueFrom(this.api.send<Project>('put', `/admin/projects/${id}`, body));
    if (this.cover) {
      const file = new FormData();
      file.append('_method', 'PUT');
      file.append('cover_image', this.cover);
      await firstValueFrom(this.api.send<Project>('post', `/admin/projects/${id}`, file));
      this.cover = null;
      this.coverIsNew.set(false);
    }
    return updated;
  }

  private async attempt(failures: string[], label: string, run: () => Observable<unknown>): Promise<boolean> {
    try {
      await firstValueFrom(run());
      return true;
    } catch (error: unknown) {
      failures.push(`${label} (${errorText(error)})`);
      return false;
    }
  }

  private load(id: number): void {
    this.id.set(id);
    void this.reload(id);
  }

  private async reload(id: number): Promise<void> {
    try {
      const item = await firstValueFrom(this.api.get<Project>(`/admin/projects/${id}`));
      this.images.set([...(item.images ?? [])].sort((a, b) => a.id - b.id));
      this.videos.set([...(item.videos ?? [])].sort((a, b) => a.id - b.id));
      this.removedImages.set([]);
      this.removedVideos.set([]);
      this.savedSlug = item.slug;
      this.savedCover = item.cover_image && !this.coverIsNew() ? item.cover_image : this.savedCover;
      if (!this.coverIsNew()) this.coverPreview.set(this.savedCover);
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
    } catch (error: unknown) {
      this.error.set(errorText(error));
    }
  }

  private releaseCover(): void {
    if (this.coverIsNew() && this.coverPreview().startsWith('blob:')) {
      URL.revokeObjectURL(this.coverPreview());
    }
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
