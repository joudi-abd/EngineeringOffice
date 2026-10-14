import { Injectable, inject } from '@angular/core';

import {
  Auth,
  GoogleAuthProvider,
  signInWithPopup,
  signOut
} from '@angular/fire/auth';

import { HttpClient } from '@angular/common/http';
import { environment } from '../../environments/environment';
import { firstValueFrom } from 'rxjs';

export interface LaravelUser {
  id: number;
  name: string;
  email: string;
}

export interface LaravelAuthResponse {
  success: boolean;
  message: string;
  data: {
    user: LaravelUser;
    token: string;
    token_type: string;
  };
}

@Injectable({
  providedIn: 'root'
})
export class FirebaseAuthService {
  private auth = inject(Auth);
  private http = inject(HttpClient);

  private apiUrl = `${environment.apiUrl}/auth/google`;


  async loginWithGoogle(): Promise<LaravelAuthResponse> {
    const provider = new GoogleAuthProvider();

    const credential = await signInWithPopup(
      this.auth,
      provider
    );


    const idToken = await credential.user.getIdToken();

    const response = await firstValueFrom(
      this.http.post<LaravelAuthResponse>(
        this.apiUrl,
        {
          id_token: idToken
        }
      )
    );

    console.log(response);

    localStorage.setItem(
      'access_token',
      response.data.token
    );

    return response;
  }


  async logout(): Promise<void> {
    localStorage.removeItem('access_token');

    await signOut(this.auth);
  }
}