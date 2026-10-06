import { Component, OnInit, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { ApiService, Page, errorText } from '../../core/api.service';
import { ConfirmService } from '../../core/confirm.service';
import { Testimonial } from '../../core/models';

@Component({
  selector: 'app-testimonials',
  imports: [RouterLink],
  templateUrl: './testimonials.component.html',
})
export class TestimonialsComponent implements OnInit {
  private readonly api = inject(ApiService);
  private readonly confirm = inject(ConfirmService);
  protected readonly page = signal<Page<Testimonial> | null>(null);
  protected readonly error = signal('');
  private current = 1;

  ngOnInit(): void {
    this.load(1);
  }

  protected load(page: number): void {
    this.current = page;
    this.api.page<Testimonial>('/admin/testimonials', page).subscribe({
      next: (result) => {
        this.page.set(result);
        this.error.set('');
      },
      error: (error: unknown) => this.error.set(errorText(error)),
    });
  }

  protected remove(item: Testimonial): void {
    void this.confirm.ask(`حذف رأي «${item.client_name}»؟`).then((accepted) => {
      if (!accepted) return;
      this.deleteReview(item);
    });
  }

  private deleteReview(item: Testimonial): void {
    this.api.remove(`/admin/testimonials/${item.id}`).subscribe({
      next: () => this.load(this.current),
      error: (error: unknown) => this.error.set(errorText(error)),
    });
  }
}
