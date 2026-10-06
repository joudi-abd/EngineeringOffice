import { Component, computed, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { SiteApi } from '../../core/site-api.service';
import { LanguageService } from '../../core/language.service';
import { gmailHref, telHref, whatsappHref } from '../../core/site-content';
import { SectionNav } from '../../core/section-nav';

@Component({
  selector: 'app-home',
  imports: [RouterLink],
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

  protected submit(event: Event): void {
    event.preventDefault();
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
        this.name.set('');
        this.mail.set('');
        this.phoneField.set('');
        this.subject.set('');
        this.message.set('');
        this.error.set('');
      },
      error: () => this.error.set(form.failed),
    });
  }
}
