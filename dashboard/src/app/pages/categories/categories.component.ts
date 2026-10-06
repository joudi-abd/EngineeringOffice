import { Component, OnInit, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { ApiService, Page, errorText } from '../../core/api.service';
import { ConfirmService } from '../../core/confirm.service';
import { ProjectCategory } from '../../core/models';

@Component({
  selector: 'app-categories',
  imports: [RouterLink],
  templateUrl: './categories.component.html',
})
export class CategoriesComponent implements OnInit {
  private readonly api = inject(ApiService);
  private readonly confirm = inject(ConfirmService);
  protected readonly page = signal<Page<ProjectCategory> | null>(null);
  protected readonly error = signal('');
  private current = 1;

  ngOnInit(): void {
    this.load(1);
  }

  protected load(page: number): void {
    this.current = page;
    this.api.page<ProjectCategory>('/admin/categories', page).subscribe({
      next: (result) => {
        this.page.set(result);
        this.error.set('');
      },
      error: (error: unknown) => this.error.set(errorText(error)),
    });
  }

  protected remove(item: ProjectCategory): void {
    void this.confirm.ask(`حذف التصنيف «${item.name}»؟`).then((accepted) => {
      if (!accepted) return;
      this.deleteCategory(item);
    });
  }

  private deleteCategory(item: ProjectCategory): void {
    this.api.remove(`/admin/categories/${item.id}`).subscribe({
      next: () => this.load(this.current),
      error: (error: unknown) => this.error.set(errorText(error)),
    });
  }
}
