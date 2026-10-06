import { DatePipe } from '@angular/common';
import { Component, OnInit, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { ApiService, Page, errorText } from '../../core/api.service';
import { ConfirmService } from '../../core/confirm.service';
import { ContactMessage } from '../../core/models';

@Component({
  selector: 'app-messages',
  imports: [RouterLink, DatePipe],
  templateUrl: './messages.component.html',
})
export class MessagesComponent implements OnInit {
  private readonly api = inject(ApiService);
  private readonly confirm = inject(ConfirmService);
  protected readonly page = signal<Page<ContactMessage> | null>(null);
  protected readonly error = signal('');
  private current = 1;

  ngOnInit(): void {
    this.load(1);
  }

  protected load(page: number): void {
    this.current = page;
    this.api.page<ContactMessage>('/admin/contact-messages', page).subscribe({
      next: (result) => {
        this.page.set(result);
        this.error.set('');
      },
      error: (error: unknown) => this.error.set(errorText(error)),
    });
  }

  protected remove(item: ContactMessage): void {
    void this.confirm.ask(`حذف رسالة «${item.subject}»؟`).then((accepted) => {
      if (!accepted) return;
      this.deleteMessage(item);
    });
  }

  private deleteMessage(item: ContactMessage): void {
    this.api.remove(`/admin/contact-messages/${item.id}`).subscribe({
      next: () => this.load(this.current),
      error: (error: unknown) => this.error.set(errorText(error)),
    });
  }
}
