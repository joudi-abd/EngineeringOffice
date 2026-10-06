import { Component, OnInit, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { ApiService, Page, errorText } from '../../core/api.service';
import { ConfirmService } from '../../core/confirm.service';
import { Service } from '../../core/models';

@Component({
  selector: 'app-services',
  imports: [RouterLink],
  templateUrl: './services.component.html',
})
export class ServicesComponent implements OnInit {
  private readonly api = inject(ApiService);
  private readonly confirm = inject(ConfirmService);
  protected readonly page = signal<Page<Service> | null>(null);
  protected readonly error = signal('');
  private current = 1;

  ngOnInit(): void {
    this.load(1);
  }

  protected load(page: number): void {
    this.current = page;
    this.api.page<Service>('/admin/services', page).subscribe({
      next: (result) => {
        this.page.set(result);
        this.error.set('');
      },
      error: (error: unknown) => this.error.set(errorText(error)),
    });
  }

  protected remove(item: Service): void {
    void this.confirm.ask(`حذف الخدمة «${item.name}»؟`).then((accepted) => {
      if (!accepted) return;
      this.deleteService(item);
    });
  }

  private deleteService(item: Service): void {
    this.api.remove(`/admin/services/${item.id}`).subscribe({
      next: () => this.load(this.current),
      error: (error: unknown) => this.error.set(errorText(error)),
    });
  }
}
