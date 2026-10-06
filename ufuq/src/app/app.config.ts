import { provideHttpClient } from '@angular/common/http';
import { ApplicationConfig, inject, provideAppInitializer, provideZoneChangeDetection } from '@angular/core';
import { provideRouter, withInMemoryScrolling } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { routes } from './app.routes';
import { ApiConfig } from './core/api-config';
import { SiteApi } from './core/site-api.service';

export const appConfig: ApplicationConfig = {
  providers: [
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes, withInMemoryScrolling({
      anchorScrolling: 'enabled',
      scrollPositionRestoration: 'top',
    })),
    provideHttpClient(),
    provideAppInitializer(() => {
      const config = inject(ApiConfig);
      const site = inject(SiteApi);
      return config.load().then(() => firstValueFrom(site.load()));
    }),
  ],
};
