import { Component, OnInit, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { ApiService, Page, errorText } from '../../core/api.service';
import { ConfirmService } from '../../core/confirm.service';
import { Project } from '../../core/models';

@Component({
  selector: 'app-projects',
  imports: [RouterLink],
  templateUrl: './projects.component.html',
})
export class ProjectsComponent implements OnInit {
  private readonly api = inject(ApiService);
  private readonly confirm = inject(ConfirmService);
  protected readonly page = signal<Page<Project> | null>(null);
  protected readonly error = signal('');
  private current = 1;

  ngOnInit(): void {
    this.load(1);
  }

  protected load(page: number): void {
    this.current = page;
    this.api.page<Project>('/admin/projects', page).subscribe({
      next: (result) => {
        this.page.set(result);
        this.error.set('');
      },
      error: (error: unknown) => this.error.set(errorText(error)),
    });
  }

  protected remove(item: Project): void {
    void this.confirm.ask(`حذف المشروع «${item.title}»؟`).then((accepted) => {
      if (!accepted) return;
      this.deleteProject(item);
    });
  }

  private deleteProject(item: Project): void {
    this.api.remove(`/admin/projects/${item.id}`).subscribe({
      next: () => this.load(this.current),
      error: (error: unknown) => this.error.set(errorText(error)),
    });
  }

  protected statusLabel(status: Project['status']): string {
    if (status === 'planning') return 'تخطيط';
    if (status === 'in_progress') return 'قيد التنفيذ';
    return 'مكتمل';
  }
}
