import { Component, DestroyRef, inject } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { AuthService } from './core/auth.service';
import { LanguageService } from './core/language.service';
import { startMotion } from './core/motion';
import { ThemeService } from './core/theme.service';
import { AuthDialogComponent } from './layout/auth-dialog/auth-dialog.component';
import { SiteFooterComponent } from './layout/site-footer/site-footer.component';
import { SiteHeaderComponent } from './layout/site-header/site-header.component';
import { WhatsappButtonComponent } from './layout/whatsapp-button/whatsapp-button.component';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, SiteHeaderComponent, SiteFooterComponent, WhatsappButtonComponent, AuthDialogComponent],
  templateUrl: './app.component.html',
  styleUrl: './app.component.scss',
})
export class AppComponent {
  protected readonly i18n = inject(LanguageService);

  constructor() {
    // Checks a saved sign-in once, so a returning visitor is recognised before they click anything.
    void inject(AuthService).restore();
    inject(ThemeService);
    const stop = startMotion();
    inject(DestroyRef).onDestroy(stop);
  }
}
