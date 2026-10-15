import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthGate } from './auth-gate';

/**
 * The account page is for signed-in visitors. A guest who opens its address gets the sign-in window first;
 * if they close it without signing in they land on the home page instead of an empty account page.
 */
export const profileGuard: CanActivateFn = async () => {
  const signedIn = await inject(AuthGate).ensure('profile');
  return signedIn ? true : inject(Router).createUrlTree(['/']);
};
