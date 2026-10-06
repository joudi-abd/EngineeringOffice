import { Injectable, signal } from '@angular/core';

interface ConfirmRequest {
  message: string;
  resolve: (accepted: boolean) => void;
}

@Injectable({ providedIn: 'root' })
export class ConfirmService {
  readonly pending = signal<ConfirmRequest | null>(null);

  ask(message: string): Promise<boolean> {
    const current = this.pending();
    if (current) current.resolve(false);
    return new Promise((resolve) => {
      this.pending.set({ message, resolve });
    });
  }

  close(accepted: boolean): void {
    const current = this.pending();
    if (!current) return;
    this.pending.set(null);
    current.resolve(accepted);
  }
}
