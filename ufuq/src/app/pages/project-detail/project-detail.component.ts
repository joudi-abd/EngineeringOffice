import { Component, ElementRef, HostListener, OnDestroy, computed, effect, inject, signal, viewChild } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { map } from 'rxjs';
import { LanguageService } from '../../core/language.service';
import { AuthGate } from '../../core/auth-gate';
import { AuthService } from '../../core/auth.service';
import { httpStatus, SiteApi } from '../../core/site-api.service';
import { Project, Testimonial, paragraphs } from '../../core/site-content';

@Component({
  selector: 'app-project-detail',
  imports: [RouterLink],
  templateUrl: './project-detail.component.html',
  styleUrl: './project-detail.component.scss',
})
export class ProjectDetailComponent implements OnDestroy {
  private readonly route = inject(ActivatedRoute);
  private readonly sanitizer = inject(DomSanitizer);
  protected readonly i18n = inject(LanguageService);
  protected readonly site = inject(SiteApi);
  private readonly gate = inject(AuthGate);
  private readonly auth = inject(AuthService);
  private readonly dialog = viewChild<ElementRef<HTMLDialogElement>>('reviewDialog');

  protected readonly stars = [1, 2, 3, 4, 5];
  protected readonly rating = signal(0);
  protected readonly name = signal('');
  protected readonly email = signal('');
  protected readonly text = signal('');
  protected readonly consent = signal(false);
  protected readonly error = signal('');
  protected readonly thanks = signal(false);
  protected readonly status = signal<'loading' | 'ready' | 'missing'>('loading');
  protected readonly rawRecord = signal<Project | null>(null);
  protected readonly rawReviews = signal<Testimonial[]>([]);
  protected readonly record = computed(() => {
    const project = this.rawRecord();
    return project ? this.site.localizeProject(project) : null;
  });
  protected readonly reviews = computed(() => this.rawReviews().map((review) => this.site.localizeReview(review)));
  protected readonly viewer = signal<number | null>(null);
  private touchX = 0;
  private swiped = false;

  private readonly slug = toSignal(
    this.route.paramMap.pipe(map((params) => params.get('slug') ?? '')),
    { initialValue: this.route.snapshot.paramMap.get('slug') ?? '' },
  );

  protected readonly copy = computed(() => paragraphs(this.record()?.description ?? null));

  protected readonly gallery = computed(() => {
    const project = this.record();
    if (!project) return [] as GalleryShot[];
    const photos = [...(project.images ?? [])].sort((a, b) => a.id - b.id);
    if (photos.length) {
      return photos.map((image) => ({
        id: image.id,
        src: this.imageSrc(image),
        alt: image.alt_text || project.title,
      }));
    }
    const cover = this.site.media(project.cover_image);
    return cover ? [{ id: 0, src: cover, alt: project.title }] : [];
  });

  protected readonly videoItems = computed(() => {
    const project = this.record();
    if (!project) return [] as VideoShot[];
    return [...(project.videos ?? [])]
      .sort((a, b) => a.id - b.id)
      .flatMap((video): VideoShot[] => {
        const title = video.title || project.title;
        const file = this.site.media(video.video_url || video.video_path);
        if (file) return [{ id: video.id, kind: 'file', src: file, embed: null, title }];
        const link = (video.external_url ?? '').trim();
        if (!/^https?:\/\//i.test(link)) return [];
        const embed = embedUrl(link);
        return [
          embed
            ? { id: video.id, kind: 'embed', src: link, embed: this.sanitizer.bypassSecurityTrustResourceUrl(embed), title }
            : { id: video.id, kind: 'link', src: link, embed: null, title },
        ];
      });
  });

  /** First three images, shown the way Facebook lays out a post's photos. */
  protected readonly preview = computed(() =>
    this.gallery()
      .slice(0, 3)
      .map((image, index) => ({ ...image, index })),
  );

  /** Images beyond the first three; shown as "+N" over the last tile. */
  protected readonly extra = computed(() => Math.max(0, this.gallery().length - 3));

  protected readonly current = computed(() => {
    const images = this.gallery();
    const index = this.viewer();
    return images[index ?? 0] ?? { id: 0, src: '', alt: '' };
  });

  constructor() {
    this.i18n.pageKind.set('project');
    effect((onCleanup) => {
      const slug = this.slug();
      this.status.set('loading');
      this.rawRecord.set(null);
      this.rawReviews.set([]);
      this.viewer.set(null);
      let reviewsSub: { unsubscribe(): void } | undefined;
      if (!slug) {
        this.status.set('missing');
        return;
      }
      const sub = this.site.project(slug).subscribe((project) => {
        this.rawRecord.set(project);
        this.status.set(project ? 'ready' : 'missing');
        reviewsSub?.unsubscribe();
        if (!project) return;
        reviewsSub = this.site.reviews(project.id).subscribe((items) => this.rawReviews.set(items));
      });
      onCleanup(() => {
        sub.unsubscribe();
        reviewsSub?.unsubscribe();
      });
    });
    effect(() => this.syncMeta());
    effect(() => {
      document.body.style.overflow = this.viewer() == null ? '' : 'hidden';
    });
  }

  ngOnDestroy(): void {
    document.body.style.overflow = '';
    if (this.i18n.pageKind() === 'project') this.i18n.pageKind.set('home');
    this.i18n.pageMeta.set(null);
  }

  protected openImage(index: number): void {
    this.viewer.set(index);
  }

  protected closeViewer(): void {
    if (this.swiped) {
      this.swiped = false;
      return;
    }
    this.viewer.set(null);
  }

  protected step(event: Event, delta: number): void {
    event.stopPropagation();
    const total = this.gallery().length;
    const current = this.viewer();
    if (current == null || total < 2) return;
    this.viewer.set((current + delta + total) % total);
  }

  protected touchStart(event: TouchEvent): void {
    this.touchX = event.changedTouches[0]?.clientX ?? 0;
  }

  protected touchEnd(event: TouchEvent): void {
    if (this.gallery().length < 2) return;
    const end = event.changedTouches[0]?.clientX ?? this.touchX;
    const delta = end - this.touchX;
    if (Math.abs(delta) < 48) return;
    this.swiped = true;
    this.viewer.update((current) => {
      if (current == null) return current;
      const total = this.gallery().length;
      const move = delta < 0 ? 1 : -1;
      return (current + move + total) % total;
    });
  }

  @HostListener('document:keydown', ['$event'])
  protected onKey(event: KeyboardEvent): void {
    if (this.viewer() == null) return;
    if (event.key === 'Escape') this.viewer.set(null);
    if (event.key === 'ArrowRight') this.step(event, -1);
    if (event.key === 'ArrowLeft') this.step(event, 1);
  }

  protected imageSrc(image: { image_url?: string | null; image_path: string }): string {
    return this.site.media(image.image_url || image.image_path);
  }

  /**
   * A star opens the review form, but writing a review needs an account. A guest gets the sign-in window
   * first; the stars they picked are kept, and the form opens by itself once they are signed in.
   */
  protected async choose(value: number): Promise<void> {
    this.rating.set(value);
    this.error.set('');
    if (!(await this.gate.ensure('review'))) return;
    this.fillFromAccount();
    this.dialog()?.nativeElement.showModal();
  }

  /** Fills the name and email of the review with the ones from the account. */
  private fillFromAccount(): void {
    const user = this.auth.user();
    if (!user) return;
    if (!this.name().trim()) this.name.set(this.auth.displayName());
    if (!this.email().trim()) this.email.set(user.email);
  }

  protected setField(field: 'name' | 'email' | 'text', event: Event): void {
    const value = (event.target as HTMLInputElement | HTMLTextAreaElement).value;
    if (field === 'name') this.name.set(value);
    if (field === 'email') this.email.set(value);
    if (field === 'text') this.text.set(value);
    this.error.set('');
  }

  protected setConsent(event: Event): void {
    this.consent.set((event.target as HTMLInputElement).checked);
    this.error.set('');
  }

  protected async submit(event: Event): Promise<void> {
    event.preventDefault();
    // The session may have ended while the form was open (signed out in another tab, token expired).
    if (!(await this.gate.ensure('review'))) return;
    const detail = this.i18n.content().projectsPage.detail;
    const project = this.record();
    const client_name = this.name().trim();
    const client_email = this.email().trim();
    const content = this.text().trim();
    const rating = this.rating();
    if (!project || !client_name || !client_email || !content || !this.consent() || rating < 1 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(client_email)) {
      this.error.set(detail.invalid);
      return;
    }
    this.site.sendReview(project.id, { client_name, client_email, content, rating }).subscribe({
      next: () => {
        this.thanks.set(true);
        this.dialog()?.nativeElement.close();
        this.site.reviews(project.id).subscribe((items) => this.rawReviews.set(items));
      },
      error: (error: unknown) => {
        this.error.set(httpStatus(error) === 409 ? detail.emailTaken : detail.failed);
      },
    });
  }

  protected closeDialog(): void {
    this.dialog()?.nativeElement.close();
  }

  protected onDialogClose(): void {
    this.name.set('');
    this.email.set('');
    this.text.set('');
    this.consent.set(false);
    this.error.set('');
  }

  protected onBackdrop(event: MouseEvent): void {
    if (event.target === this.dialog()?.nativeElement) this.closeDialog();
  }

  private syncMeta(): void {
    const content = this.i18n.content();
    const project = this.record();
    this.i18n.pageMeta.set(
      project
        ? { title: `${project.title} | ${content.projectsPage.eyebrow}`, description: project.short_description ?? '' }
        : { title: content.projectsPage.detail.missingTitle, description: content.projectsPage.metaDescription },
    );
  }
}

interface GalleryShot {
  id: number;
  src: string;
  alt: string;
  index?: number;
}

interface VideoShot {
  id: number;
  kind: 'file' | 'embed' | 'link';
  src: string;
  embed: SafeResourceUrl | null;
  title: string;
}

function embedUrl(link: string): string | null {
  let url: URL;
  try {
    url = new URL(link);
  } catch {
    return null;
  }
  const host = url.hostname.replace(/^www\./, '').replace(/^m\./, '');
  let id = '';
  if (host === 'youtu.be') id = url.pathname.split('/')[1] ?? '';
  else if (host === 'youtube.com' || host === 'youtube-nocookie.com') {
    const parts = url.pathname.split('/').filter(Boolean);
    id = url.searchParams.get('v') ?? (['embed', 'shorts', 'live'].includes(parts[0]) ? parts[1] ?? '' : '');
  }
  if (/^[\w-]{6,20}$/.test(id)) return `https://www.youtube-nocookie.com/embed/${id}`;
  if (host === 'vimeo.com' || host === 'player.vimeo.com') {
    const vimeo = url.pathname.split('/').filter(Boolean).find((part) => /^\d+$/.test(part));
    if (vimeo) return `https://player.vimeo.com/video/${vimeo}`;
  }
  return null;
}
