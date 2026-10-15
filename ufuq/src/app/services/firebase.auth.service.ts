import { Injectable, inject } from '@angular/core';
import { Auth, GoogleAuthProvider, signInWithPopup, signOut } from '@angular/fire/auth';

/**
 * The Google side of signing in. It only talks to Firebase: it opens Google's window and hands back the
 * Firebase ID token. Turning that token into an account session is the job of `AuthService`
 * (POST /auth/google), so the rest of the site never touches Firebase directly.
 */
@Injectable({ providedIn: 'root' })
export class FirebaseAuthService {
  private readonly auth = inject(Auth);

  /** Opens Google's account chooser and returns the Firebase ID token. Rejects with the Firebase error. */
  async googleIdToken(): Promise<string> {
    const provider = new GoogleAuthProvider();
    provider.setCustomParameters({ prompt: 'select_account' });
    const credential = await signInWithPopup(this.auth, provider);
    return credential.user.getIdToken();
  }

  /** Ends the Firebase session too, so the next Google sign-in asks which account to use. */
  async signOut(): Promise<void> {
    try {
      await signOut(this.auth);
    } catch {
      /* nothing to end */
    }
  }
}
