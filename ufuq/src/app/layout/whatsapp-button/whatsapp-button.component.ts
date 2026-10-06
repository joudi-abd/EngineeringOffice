import { Component, computed, inject } from '@angular/core';
import { LanguageService } from '../../core/language.service';
import { SiteApi } from '../../core/site-api.service';
import { whatsappHref } from '../../core/site-content';

@Component({
  selector: 'app-whatsapp-button',
  templateUrl: './whatsapp-button.component.html',
  styleUrl: './whatsapp-button.component.scss',
})
export class WhatsappButtonComponent {
  protected readonly i18n = inject(LanguageService);
  private readonly site = inject(SiteApi);
  protected readonly link = computed(() => {
    const number = this.site.setting('whatsapp');
    return number ? whatsappHref(number) : '';
  });
}
