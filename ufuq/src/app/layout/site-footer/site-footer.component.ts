import { Component, computed, inject } from '@angular/core';
import { LanguageService } from '../../core/language.service';
import { SiteApi } from '../../core/site-api.service';
import { gmailHref, telHref } from '../../core/site-content';
import { SectionNav } from '../../core/section-nav';

@Component({
  selector: 'app-site-footer',
  templateUrl: './site-footer.component.html',
  styleUrl: './site-footer.component.scss',
})
export class SiteFooterComponent {
  protected readonly i18n = inject(LanguageService);
  protected readonly sections = inject(SectionNav);
  protected readonly site = inject(SiteApi);
  protected readonly phone = computed(() => this.site.setting('phone'));
  protected readonly email = computed(() => this.site.setting('email'));
  protected readonly address = computed(() => this.site.setting('address'));
  protected readonly hours = computed(() => this.site.setting('hours'));
  protected readonly phoneLink = computed(() => telHref(this.phone()));
  protected readonly emailLink = computed(() => gmailHref(this.email()));
  protected readonly year = new Date().getFullYear();
}
