import { Component, OnDestroy, computed, inject } from '@angular/core';
import { LanguageService } from '../../core/language.service';
import { SiteApi } from '../../core/site-api.service';
import { SectionNav } from '../../core/section-nav';

@Component({
  selector: 'app-about',
  templateUrl: './about.component.html',
  styleUrl: './about.component.scss',
})
export class AboutComponent implements OnDestroy {
  protected readonly i18n = inject(LanguageService);
  protected readonly sections = inject(SectionNav);
  protected readonly site = inject(SiteApi);
  protected readonly services = computed(() => this.site.services());
  protected readonly team = computed(() => this.site.team());

  constructor() {
    this.i18n.pageKind.set('about');
    this.site.load().subscribe();
  }

  ngOnDestroy(): void {
    this.i18n.pageKind.set('home');
  }
}
