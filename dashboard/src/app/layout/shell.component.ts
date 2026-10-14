import { Component, OnInit, computed, inject } from '@angular/core';
import { Router, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { AuthService } from '../core/auth.service';
import { ConfirmDialogComponent } from './confirm-dialog.component';
import { ThemeToggleComponent } from './theme-toggle.component';

@Component({
  selector: 'app-shell',
  imports: [RouterOutlet, RouterLink, RouterLinkActive, ThemeToggleComponent, ConfirmDialogComponent],
  templateUrl: './shell.component.html',
})
export class ShellComponent implements OnInit {
  protected readonly auth = inject(AuthService);
  private readonly router = inject(Router);

  protected readonly nav = [
    { path: '/', label: 'الرئيسية', exact: true, icon: 'M3.5 11.5 12 4l8.5 7.5M5.5 10v9.5h13V10M10 19.5v-5h4v5' },
    { path: '/categories', label: 'التصنيفات', exact: false, icon: 'M4 4h7v7H4zM13 4h7v7h-7zM4 13h7v7H4zM13 13h7v7h-7z' },
    { path: '/projects', label: 'المشاريع', exact: false, icon: 'M5 21V5l9-2v18M14 8h5v13M3.5 21h17M9 8h1M9 12h1M9 16h1' },
    { path: '/services', label: 'الخدمات', exact: false, icon: 'M3.5 17 17 3.5l3.5 3.5L7 20.5zM8.5 12l2 2M11.5 9l2 2M14.5 6l2 2' },
    { path: '/team', label: 'الفريق', exact: false, icon: 'M9 11a3.2 3.2 0 1 0 0-6.4A3.2 3.2 0 0 0 9 11zM3 20c.7-3.3 3-5 6-5s5.3 1.7 6 5M16.5 11a2.6 2.6 0 1 0 0-5.2M17 15.2c2 .3 3.4 1.8 4 4.3' },
    { path: '/testimonials', label: 'الآراء', exact: false, icon: 'M12 3.5l2.6 5.4 5.9.8-4.3 4.1 1 5.9-5.2-2.8-5.2 2.8 1-5.9-4.3-4.1 5.9-.8z' },
    { path: '/messages', label: 'الرسائل', exact: false, icon: 'M3.5 6h17v12h-17zM3.5 7l8.5 6 8.5-6' },
    { path: '/settings', label: 'الإعدادات', exact: false, icon: 'M4 7h9M17 7h3M4 17h3M11 17h9M15 5v4M9 15v4' },
  ];

  protected readonly initial = computed(() => (this.auth.user()?.name || 'م').trim().charAt(0).toUpperCase());
  protected readonly today = new Intl.DateTimeFormat('ar', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }).format(new Date());

  ngOnInit(): void {
    if (!this.auth.user()) {
      this.auth.me().subscribe({ error: () => undefined });
    }
  }

  protected logout(): void {
    this.auth.logout().subscribe({
      next: () => void this.router.navigate(['/login']),
      error: () => {
        this.auth.clear();
        void this.router.navigate(['/login']);
      },
    });
  }
}
