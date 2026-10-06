import { Component, OnDestroy, inject } from '@angular/core';
import { LanguageService } from '../../core/language.service';
import { SiteApi } from '../../core/site-api.service';
import { SectionNav } from '../../core/section-nav';

@Component({
  selector: 'app-services',
  templateUrl: './services.component.html',
  styleUrl: './services.component.scss',
})
export class ServicesComponent implements OnDestroy {
  protected readonly i18n = inject(LanguageService);
  protected readonly sections = inject(SectionNav);
  protected readonly site = inject(SiteApi);

  constructor() {
    this.i18n.pageKind.set('services');
  }

  ngOnDestroy(): void {
    this.i18n.pageKind.set('home');
  }
}

