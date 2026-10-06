import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { catchError, forkJoin, of } from 'rxjs';
import { ApiService } from '../../core/api.service';
import { ContactMessage, Project, Testimonial } from '../../core/models';

interface Slice {
  label: string;
  value: number;
  tone: string;
}

interface Arc extends Slice {
  dash: string;
  offset: number;
}

@Component({
  selector: 'app-overview',
  imports: [RouterLink],
  templateUrl: './overview.component.html',
})
export class OverviewComponent implements OnInit {
  private readonly api = inject(ApiService);

  protected readonly projects = signal<number | null>(null);
  protected readonly messages = signal<number | null>(null);
  protected readonly reviews = signal<number | null>(null);
  protected readonly unread = signal<number | null>(null);
  private readonly projectItems = signal<Project[]>([]);
  private readonly messageItems = signal<ContactMessage[]>([]);
  private readonly reviewItems = signal<Testimonial[]>([]);

  protected readonly statusSlices = computed(() => [
    { label: 'منجز', value: countStatus(this.projectItems(), 'completed'), tone: 'done' },
    { label: 'قيد التنفيذ', value: countStatus(this.projectItems(), 'in_progress'), tone: 'work' },
    { label: 'تخطيط', value: countStatus(this.projectItems(), 'planning'), tone: 'plan' },
  ]);

  protected readonly statusRing = computed(() => ring(this.statusSlices()));

  protected readonly ratingBars = computed(() => {
    const items = this.reviewItems();
    const bars = [1, 2, 3, 4, 5].map((stars) => ({
      stars,
      count: items.filter((item) => Number(item.rating) === stars).length,
    }));
    const peak = Math.max(...bars.map((bar) => bar.count), 1);
    return bars.map((bar) => ({ ...bar, percent: (bar.count / peak) * 100 }));
  });

  protected readonly readMessages = computed(() =>
    this.messageItems().filter((item) => item.status === 'read').length,
  );

  ngOnInit(): void {
    forkJoin({
      projects: this.api.all<Project>('/admin/projects').pipe(catchError(() => of(null))),
      messages: this.api.all<ContactMessage>('/admin/contact-messages').pipe(catchError(() => of(null))),
      reviews: this.api.all<Testimonial>('/admin/testimonials').pipe(catchError(() => of(null))),
    }).subscribe(({ projects, messages, reviews }) => {
      if (projects) {
        this.projectItems.set(projects);
        this.projects.set(projects.length);
      }
      if (messages) {
        this.messageItems.set(messages);
        this.messages.set(messages.length);
        this.unread.set(messages.filter((item) => item.status === 'new').length);
      }
      if (reviews) {
        this.reviewItems.set(reviews);
        this.reviews.set(reviews.length);
      }
    });
  }
}

function countStatus(items: Project[], status: Project['status']): number {
  return items.filter((item) => item.status === status).length;
}

function ring(slices: Slice[]): { total: number; parts: Arc[] } {
  const total = slices.reduce((sum, slice) => sum + slice.value, 0);
  const circumference = 2 * Math.PI * 54;
  let drawn = 0;
  const parts = slices.filter((slice) => slice.value > 0).map((slice) => {
    const length = (slice.value / total) * circumference;
    const part = { ...slice, dash: `${length} ${circumference - length}`, offset: -drawn };
    drawn += length;
    return part;
  });
  return { total, parts };
}
