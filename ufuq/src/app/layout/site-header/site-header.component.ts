import { Component, HostListener, OnDestroy, computed, inject, signal } from '@angular/core';
import { NavigationEnd, Router, RouterLink } from '@angular/router';
import { filter } from 'rxjs';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { AuthService } from '../../core/auth.service';
import { AUTH_COPY } from '../../core/auth-content';
import { LanguageService } from '../../core/language.service';
import { SiteApi } from '../../core/site-api.service';
import { NavItem, telHref } from '../../core/site-content';
import { SectionNav } from '../../core/section-nav';
import { THEME_COPY, ThemeService } from '../../core/theme.service';

@Component({
  selector: 'app-site-header',
  imports: [RouterLink],
  templateUrl: './site-header.component.html',
  styleUrl: './site-header.component.scss',
})
export class SiteHeaderComponent implements OnDestroy {
  protected readonly i18n = inject(LanguageService);
  protected readonly sections = inject(SectionNav);
  protected readonly site = inject(SiteApi);
  protected readonly auth = inject(AuthService);
  protected readonly theme = inject(ThemeService);
  protected readonly account = computed(() => AUTH_COPY[this.i18n.lang()].account);
  protected readonly themeCopy = computed(() => THEME_COPY[this.i18n.lang()]);
  private readonly router = inject(Router);
  protected readonly phone = computed(() => this.site.setting('phone'));
  protected readonly phoneLink = computed(() => telHref(this.phone()));
  protected readonly logo = computed(() => this.site.logo());

  protected readonly scrolled = signal(false);
  protected readonly menuOpen = signal(false);
  protected readonly active = signal('top');
  protected readonly path = signal(this.currentPath());
  /** The hero follows the theme too, so the light-on-dark logo is only right in the dark theme. */
  protected readonly artwork = computed(() => {
    const light = this.theme.theme() === 'dark' ? 'light' : 'dark';
    return this.i18n.lang() === 'ar' ? `brand/logo-ar-${light}.png` : `brand/logo-en-${light}-compact.png`;
  });

  constructor() {
    this.router.events.pipe(
      filter((event) => event instanceof NavigationEnd),
      takeUntilDestroyed(),
    ).subscribe(() => {
      this.path.set(this.currentPath());
      this.closeMenu();
    });
  }

  ngOnDestroy(): void {
    document.body.style.overflow = '';
  }

  protected toggleMenu(event: Event): void {
    event.stopPropagation();
    this.menuOpen.update((open) => !open);
    document.body.style.overflow = this.menuOpen() ? 'hidden' : '';
  }

  protected follow(event: Event, id: string): void {
    this.closeMenu();
    this.sections.go(event, id);
  }

  protected open(event: Event, item: NavItem): void {
    this.closeMenu();
    this.sections.open(event, item);
  }

  protected isCurrent(item: NavItem): boolean {
    if (item.href === '/projects') {
      return this.path() === '/projects' || this.path().startsWith('/projects/');
    }
    if (item.href) return this.path() === item.href;
    return this.path() === '/' && this.active() === item.id;
  }

  private currentPath(): string {
    return this.router.url.split(/[?#]/)[0] || '/';
  }

  protected signOut(): void {
    this.closeMenu();
    void this.auth.logout();
  }

  protected closeMenu(): void {
    this.menuOpen.set(false);
    document.body.style.overflow = '';
  }

  @HostListener('document:click')
  onDocumentClick(): void {
    if (this.menuOpen()) this.closeMenu();
  }

  @HostListener('document:keydown.escape')
  onEscape(): void {
    if (this.menuOpen()) this.closeMenu();
  }

  @HostListener('window:scroll')
  onWindowScroll(): void {
    this.scrolled.set(window.scrollY > 24);
    const marker = window.scrollY + 140;
    let current = 'top';
    for (const id of ['about', 'services', 'projects', 'contact']) {
      const el = document.getElementById(id);
      if (el && el.offsetTop <= marker) current = id;
    }
    this.active.set(current);
  }
}
