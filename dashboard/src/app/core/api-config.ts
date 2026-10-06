import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class ApiConfig {
  apiUrl = 'http://127.0.0.1:8000/api';

  load(): Promise<void> {
    const url = new URL('config.json', document.baseURI).toString();
    return fetch(url)
      .then((response) => (response.ok ? response.json() : null))
      .then((data: { apiUrl?: string } | null) => {
        if (data?.apiUrl) this.apiUrl = data.apiUrl.replace(/\/$/, '');
      })
      .catch(() => undefined);
  }
}
