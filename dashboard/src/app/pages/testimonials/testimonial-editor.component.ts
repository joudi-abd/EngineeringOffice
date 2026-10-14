import { Component, OnInit, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { ApiService, errorText } from '../../core/api.service';
import { Testimonial } from '../../core/models';

import { SelectComponent, SelectOption } from '../../layout/select.component';

@Component({
  selector: 'app-testimonial-editor',
  imports: [ReactiveFormsModule, RouterLink, SelectComponent],
  templateUrl: './testimonial-editor.component.html',
})
export class TestimonialEditorComponent implements OnInit {
  private readonly api = inject(ApiService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly formBuilder = inject(FormBuilder);

  protected readonly ratingOptions: SelectOption[] = [5, 4, 3, 2, 1].map((n) => ({ value: String(n), label: '★'.repeat(n) + '  ' + n }));
  protected readonly error = signal('');
  protected readonly busy = signal(false);
  protected readonly projectTitle = signal('');
  protected readonly form = this.formBuilder.nonNullable.group({
    client_name: ['', Validators.required],
    content: ['', Validators.required],
    rating: ['5', Validators.required],
  });

  ngOnInit(): void {
    const id = Number(this.route.snapshot.paramMap.get('id'));
    this.api.get<Testimonial>(`/admin/testimonials/${id}`).subscribe({
      next: (item) => {
        this.projectTitle.set(item.project?.title ?? '');
        this.form.patchValue({
          client_name: item.client_name,
          content: item.content,
          rating: String(item.rating),
        });
      },
      error: (error: unknown) => this.error.set(errorText(error)),
    });
  }

  protected save(): void {
    if (this.form.invalid) {
      this.error.set('الاسم والنص والتقييم مطلوبة.');
      return;
    }
    this.busy.set(true);
    const id = Number(this.route.snapshot.paramMap.get('id'));
    const value = this.form.getRawValue();
    this.api.send('put', `/admin/testimonials/${id}`, {
      client_name: value.client_name.trim(),
      content: value.content.trim(),
      rating: Number(value.rating),
    }).subscribe({
      next: () => void this.router.navigate(['/testimonials']),
      error: (error: unknown) => {
        this.busy.set(false);
        this.error.set(errorText(error));
      },
    });
  }
}
