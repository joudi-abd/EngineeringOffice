import { Component, OnInit, inject } from '@angular/core';
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
    { path: '/', label: 'الرئيسية', exact: true },
    { path: '/categories', label: 'التصنيفات', exact: false },
    { path: '/projects', label: 'المشاريع', exact: false },
    { path: '/services', label: 'الخدمات', exact: false },
    { path: '/team', label: 'الفريق', exact: false },
    { path: '/testimonials', label: 'الآراء', exact: false },
    { path: '/messages', label: 'الرسائل', exact: false },
    { path: '/settings', label: 'الإعدادات', exact: false },
  ];

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
