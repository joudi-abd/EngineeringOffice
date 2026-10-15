import { Component, computed, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { AuthGate } from '../../core/auth-gate';
import { AuthService } from '../../core/auth.service';
import { SiteApi } from '../../core/site-api.service';
import { LanguageService } from '../../core/language.service';
import { gmailHref, telHref, whatsappHref } from '../../core/site-content';
import { SectionNav } from '../../core/section-nav';
import { ServiceIconComponent } from '../../layout/service-icon/service-icon.component';
import { SocialLinksComponent } from '../../layout/social-links/social-links.component';

@Component({
  selector: 'app-home',
  imports: [RouterLink, ServiceIconComponent, SocialLinksComponent],
  templateUrl: './home.component.html',
  styleUrl: './home.component.scss',
})
export class HomeComponent {
  protected readonly i18n = inject(LanguageService);
  protected readonly sections = inject(SectionNav);
  protected readonly site = inject(SiteApi);
  protected readonly services = computed(() => this.site.services());
  protected readonly team = computed(() => this.site.team());
  protected readonly featured = computed(() => this.site.projects().filter((item) => item.is_featured === true));
  protected readonly phone = computed(() => this.site.setting('phone'));
  protected readonly email = computed(() => this.site.setting('email'));
  protected readonly address = computed(() => this.site.setting('address'));
  protected readonly hours = computed(() => this.site.setting('hours'));
  protected readonly phoneLink = computed(() => telHref(this.phone()));
  protected readonly emailLink = computed(() => gmailHref(this.email()));
  protected readonly whatsappLink = computed(() => {
    const number = this.site.setting('whatsapp');
    return number ? whatsappHref(number) : '';
  });

  private readonly gate = inject(AuthGate);
  private readonly auth = inject(AuthService);

  protected readonly name = signal('');
  protected readonly mail = signal('');
  protected readonly phoneField = signal('');
  protected readonly subject = signal('');
  protected readonly message = signal('');
  protected readonly error = signal('');
  protected readonly sent = signal(false);

  constructor() {
    this.site.load().subscribe();
  }

  protected scrollNext(): void {
    this.sections.scrollTo('about');
  }

  protected setField(field: 'name' | 'mail' | 'phone' | 'subject' | 'message', event: Event): void {
    const value = (event.target as HTMLInputElement | HTMLTextAreaElement).value;
    if (field === 'name') this.name.set(value);
    if (field === 'mail') this.mail.set(value);
    if (field === 'phone') this.phoneField.set(value);
    if (field === 'subject') this.subject.set(value);
    if (field === 'message') this.message.set(value);
    this.error.set('');
  }

  /**
   * Sending a message needs an account. A guest who presses "send" gets the sign-in window first; whatever they
   * typed stays in the form, and the message goes out by itself as soon as they are signed in.
   */
  protected async submit(event: Event): Promise<void> {
    event.preventDefault();
    if (!(await this.gate.ensure('message'))) return;
    this.fillFromAccount();
    const form = this.i18n.content().contact;
    const name = this.name().trim();
    const email = this.mail().trim();
    const subject = this.subject().trim();
    const message = this.message().trim();
    const phone = this.phoneField().trim();
    if (!name || !email || !subject || !message || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      this.error.set(form.invalid);
      return;
    }
    this.site.sendMessage({
      name,
      email,
      phone: phone || null,
      subject,
      message,
    }).subscribe({
      next: () => {
        this.sent.set(true);
        this.subject.set('');
        this.message.set('');
        this.error.set('');
      },
      error: () => this.error.set(form.failed),
    });
  }

  /** Fills the name, email and phone the visitor left empty with the ones from their account. */
  private fillFromAccount(): void {
    const user = this.auth.user();
    if (!user) return;
    if (!this.name().trim()) this.name.set(this.auth.displayName());
    if (!this.mail().trim()) this.mail.set(user.email);
    if (!this.phoneField().trim() && user.phone) this.phoneField.set(user.phone);
  }
}
