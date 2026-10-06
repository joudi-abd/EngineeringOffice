import { Injectable, inject } from '@angular/core';
import { Router } from '@angular/router';
import { NavItem } from './site-content';

@Injectable({ providedIn: 'root' })
export class SectionNav {
  private readonly router = inject(Router);

  open(event: Event, item: NavItem): void {
    if (item.href) {
      event.preventDefault();
      void this.router.navigateByUrl(item.href);
      return;
    }
    this.go(event, item.id);
  }

  go(event: Event, id: string): void {
    event.preventDefault();
    const path = this.router.url.split(/[?#]/)[0];
    if (path !== '/') {
      const fragment = id === 'top' ? undefined : id;
      void this.router.navigate(['/'], { fragment }).then(() => {
        if (!fragment) return;
        window.setTimeout(() => this.align(fragment), 0);
      });
      return;
    }
    this.scrollTo(id);
  }

  scrollTo(id: string): void {
    const behavior = this.behavior();
    const next = id === 'top' ? '/' : `/#${id}`;
    history.pushState(null, '', next);
    if (id === 'top') {
      window.scrollTo({ top: 0, behavior });
      return;
    }
    this.align(id);
  }

  private align(id: string): void {
    const el = document.getElementById(id);
    if (!el) return;
    const header = document.querySelector('app-site-header .top');
    const offset = (header?.getBoundingClientRect().height ?? 104) + 20;
    const top = el.getBoundingClientRect().top + window.scrollY - offset;
    window.scrollTo({ top: Math.max(0, top), behavior: this.behavior() });
  }

  private behavior(): ScrollBehavior {
    return window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth';
  }
}
