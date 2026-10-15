import { Injectable, inject, signal } from '@angular/core';
import { AuthService } from './auth.service';
import { AuthReason } from './auth-content';

/**
 * The one question every "write a review" / "send a message" button asks first: is this visitor signed in?
 *
 *   if (!(await gate.ensure('message'))) return;   // the visitor can browse as a guest, but not post
 *
 * A guest gets the sign-in window (`AuthDialogComponent`, mounted once in the app shell) and the promise
 * settles when they finish: `true` once signed in, `false` if they close the window. The page that asked
 * keeps its own state, so whatever the visitor already typed or picked is still there afterwards.
 */
@Injectable({ providedIn: 'root' })
export class AuthGate {
  private readonly auth = inject(AuthService);

  /** The reason the window is open for, or null while it is closed. */
  readonly request = signal<AuthReason | null>(null);

  private settle: ((signedIn: boolean) => void) | null = null;

  ensure(reason: AuthReason): Promise<boolean> {
    return this.auth.whenReady().then(() => {
      if (this.auth.loggedIn()) return true;
      this.finish(false); // a second click while the window is open replaces the first question
      return new Promise<boolean>((resolve) => {
        this.settle = resolve;
        this.request.set(reason);
      });
    });
  }

  /** Called by the window: signed in (`true`) or dismissed (`false`). */
  finish(signedIn: boolean): void {
    const settle = this.settle;
    this.settle = null;
    this.request.set(null);
    settle?.(signedIn);
  }
}
