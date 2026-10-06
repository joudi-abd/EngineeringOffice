import { Component, OnDestroy, computed, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { LanguageService } from '../../core/language.service';
import { SiteApi } from '../../core/site-api.service';
import { SectionNav } from '../../core/section-nav';

@Component({
  selector: 'app-projects',
  imports: [RouterLink],
  templateUrl: './projects.component.html',
  styleUrl: './projects.component.scss',
})
export class ProjectsComponent implements OnDestroy {
  protected readonly i18n = inject(LanguageService);
  protected readonly sections = inject(SectionNav);
  protected readonly site = inject(SiteApi);
  protected readonly filter = signal<number | 'all'>('all');

  protected readonly categories = computed(() => this.site.categories());

  protected readonly visible = computed(() => {
    const items = this.site.projects();
    const filter = this.filter();
    return filter === 'all' ? items : items.filter((item) => item.category?.id === filter);
  });

  constructor() {
    this.i18n.pageKind.set('projects');
    this.site.load().subscribe();
  }

  ngOnDestroy(): void {
    this.i18n.pageKind.set('home');
  }
}
