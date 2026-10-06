import { Component, HostListener, inject } from '@angular/core';
import { ConfirmService } from '../core/confirm.service';

@Component({
  selector: 'app-confirm-dialog',
  template: `
    @if (confirm.pending(); as request) {
      <div class="confirm" (click)="confirm.close(false)">
        <div
          class="confirm__card"
          role="dialog"
          aria-modal="true"
          aria-labelledby="confirm-title"
          (click)="$event.stopPropagation()"
        >
          <p class="kicker" id="confirm-title">تأكيد الحذف</p>
          <p class="confirm__text">{{ request.message }}</p>
          <div class="confirm__actions">
            <button class="btn-danger" type="button" (click)="confirm.close(true)">حذف</button>
            <button class="btn-quiet" type="button" autofocus (click)="confirm.close(false)">إلغاء</button>
          </div>
        </div>
      </div>
    }
  `,
})
export class ConfirmDialogComponent {
  protected readonly confirm = inject(ConfirmService);

  @HostListener('document:keydown.escape')
  protected dismiss(): void {
    this.confirm.close(false);
  }
}
