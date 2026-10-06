import { Component, OnInit, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { ApiService, Page, errorText } from '../../core/api.service';
import { ConfirmService } from '../../core/confirm.service';
import { TeamMember } from '../../core/models';

@Component({
  selector: 'app-team',
  imports: [RouterLink],
  templateUrl: './team.component.html',
})
export class TeamComponent implements OnInit {
  private readonly api = inject(ApiService);
  private readonly confirm = inject(ConfirmService);
  protected readonly page = signal<Page<TeamMember> | null>(null);
  protected readonly error = signal('');
  private current = 1;

  ngOnInit(): void {
    this.load(1);
  }

  protected load(page: number): void {
    this.current = page;
    this.api.page<TeamMember>('/admin/team-members', page).subscribe({
      next: (result) => {
        this.page.set(result);
        this.error.set('');
      },
      error: (error: unknown) => this.error.set(errorText(error)),
    });
  }

  protected remove(item: TeamMember): void {
    void this.confirm.ask(`حذف «${item.name}» من الفريق؟`).then((accepted) => {
      if (!accepted) return;
      this.deleteMember(item);
    });
  }

  private deleteMember(item: TeamMember): void {
    this.api.remove(`/admin/team-members/${item.id}`).subscribe({
      next: () => this.load(this.current),
      error: (error: unknown) => this.error.set(errorText(error)),
    });
  }
}
