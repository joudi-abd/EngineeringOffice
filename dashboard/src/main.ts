import { bootstrapApplication } from '@angular/platform-browser';
import { appConfig } from './app/app.config';
import { AppComponent } from './app/app.component';
import { applyTheme, readTheme } from './app/core/theme.service';

applyTheme(readTheme());

bootstrapApplication(AppComponent, appConfig)
  .catch((err) => console.error(err));
