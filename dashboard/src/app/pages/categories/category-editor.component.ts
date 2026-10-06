import { Component, OnInit, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { ApiService, errorText } from '../../core/api.service';
import { ProjectCategory } from '../../core/models';
import { recordSlug } from '../../core/slug';

@Component({
  selector: 'app-category-editor',
  imports: [ReactiveFormsModule, RouterLink],
  templateUrl: './category-editor.component.html',
})
export class CategoryEditorComponent implements OnInit {
  private readonly api = inject(ApiService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly formBuilder = inject(FormBuilder);

  protected readonly error = signal('');
  protected readonly busy = signal(false);
  protected readonly id = signal<number | null>(null);
  private savedSlug = '';
  protected readonly form = this.formBuilder.nonNullable.group({
    name: ['', Validators.required],
    description: [''],
    is_active: [true],
  });

  ngOnInit(): void {
    const raw = this.route.snapshot.paramMap.get('id');
    if (!raw || raw === 'new') return;
    const id = Number(raw);
    this.id.set(id);
    this.api.get<ProjectCategory>(`/admin/categories/${id}`).subscribe({
      next: (item) => {
        this.savedSlug = item.slug;
        this.form.patchValue({
          name: item.name,
          description: item.description ?? '',
          is_active: item.is_active,
        });
      },
      error: (error: unknown) => this.error.set(errorText(error)),
    });
  }

  protected save(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      this.error.set('الاسم مطلوب.');
      return;
    }
    this.busy.set(true);
    this.error.set('');
    const value = this.form.getRawValue();
    const name = value.name.trim();
    const body = {
      name,
      slug: recordSlug(name, this.savedSlug),
      description: value.description.trim() || null,
      is_active: value.is_active,
    };
    const id = this.id();
    const request = id
      ? this.api.send<ProjectCategory>('put', `/admin/categories/${id}`, body)
      : this.api.send<ProjectCategory>('post', '/admin/categories', body);
    request.subscribe({
      next: () => void this.router.navigate(['/categories']),
      error: (error: unknown) => {
        this.busy.set(false);
        this.error.set(errorText(error));
      },
    });
  }
}
