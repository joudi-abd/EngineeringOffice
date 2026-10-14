import { Component, computed, inject } from '@angular/core';
import { LanguageService } from '../../core/language.service';
import { SiteApi } from '../../core/site-api.service';
import { gmailHref, telHref } from '../../core/site-content';
import { SectionNav } from '../../core/section-nav';
import { SocialLinksComponent } from '../social-links/social-links.component';

@Component({
  selector: 'app-site-footer',
  imports: [SocialLinksComponent],
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
  protected readonly logo = computed(() => this.site.logo());
  protected readonly blurb = computed(() => this.site.setting('company_description') || this.i18n.content().footer.blurb);
  protected readonly rights = computed(() => {
    const footer = this.i18n.content().footer;
    const name = this.site.companyName();
    return name ? `${name}. ${footer.reserved}` : footer.rights;
  });
}
