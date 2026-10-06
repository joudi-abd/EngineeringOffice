import { DatePipe } from '@angular/common';
import { Component, OnInit, inject, signal } from '@angular/core';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { ApiService, errorText } from '../../core/api.service';
import { ConfirmService } from '../../core/confirm.service';
import { ContactMessage } from '../../core/models';

@Component({
  selector: 'app-message-detail',
  imports: [RouterLink, DatePipe],
  templateUrl: './message-detail.component.html',
})
export class MessageDetailComponent implements OnInit {
  private readonly api = inject(ApiService);
  private readonly confirm = inject(ConfirmService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);

  protected readonly item = signal<ContactMessage | null>(null);
  protected readonly error = signal('');

  ngOnInit(): void {
    this.load();
  }

  protected mark(status: 'new' | 'read'): void {
    const item = this.item();
    if (!item) return;
    this.api.send<ContactMessage>('patch', `/admin/contact-messages/${item.id}`, { status }).subscribe({
      next: (updated) => this.item.set(updated),
      error: (error: unknown) => this.error.set(errorText(error)),
    });
  }

  protected remove(): void {
    const item = this.item();
    if (!item) return;
    void this.confirm.ask('حذف هذه الرسالة؟').then((accepted) => {
      if (!accepted) return;
      this.deleteMessage(item.id);
    });
  }

  private deleteMessage(id: number): void {
    this.api.remove(`/admin/contact-messages/${id}`).subscribe({
      next: () => void this.router.navigate(['/messages']),
      error: (error: unknown) => this.error.set(errorText(error)),
    });
  }

  private load(): void {
    const id = Number(this.route.snapshot.paramMap.get('id'));
    this.api.get<ContactMessage>(`/admin/contact-messages/${id}`).subscribe({
      next: (item) => this.item.set(item),
      error: (error: unknown) => this.error.set(errorText(error)),
    });
  }
}
