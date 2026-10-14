import { Component, inject, input } from '@angular/core';
import { SiteApi } from '../../core/site-api.service';

/** Brand marks for the accounts entered in the dashboard (stroke icons, 24×24). */
const MARKS: Record<string, string> = {
  facebook: 'M14.2 21v-8h2.7l.5-3.3h-3.2V7.6c0-.9.4-1.7 1.8-1.7h1.5V3.1c-.3 0-1.3-.1-2.4-.1-2.5 0-4.1 1.5-4.1 4.2v2.5H8.2V13h2.8v8z',
  instagram: 'M7.5 3.5h9a4 4 0 0 1 4 4v9a4 4 0 0 1-4 4h-9a4 4 0 0 1-4-4v-9a4 4 0 0 1 4-4zM12 8.3a3.7 3.7 0 1 0 0 7.4 3.7 3.7 0 0 0 0-7.4zM17.2 6.9h.01',
};

@Component({
  selector: 'app-social-links',
  template: `
    @if (site.social().length) {
      <ul [class.is-labelled]="labelled()" [attr.aria-label]="label()">
        @for (item of site.social(); track item.key) {
          <li>
            <a [href]="item.href" target="_blank" rel="noopener noreferrer" [attr.aria-label]="item.label">
              <svg viewBox="0 0 24 24" aria-hidden="true"><path [attr.d]="mark(item.key)" /></svg>
              @if (labelled()) {
                <span>{{ item.label }}</span>
              }
            </a>
          </li>
        }
      </ul>
    }
  `,
  styles: `
    ul {
      display: flex;
      flex-wrap: wrap;
      gap: 12px;
      margin: 0;
      padding: 0;
      list-style: none;
    }

    a {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 10px;
      width: 44px;
      height: 44px;
      border: 1px solid rgba(203, 184, 146, 0.4);
      border-radius: 999px;
      color: var(--gold-soft, #cbb892);
      text-decoration: none;
      transition:
        background 0.4s cubic-bezier(0.22, 0.61, 0.36, 1),
        color 0.4s ease,
        border-color 0.4s ease,
        transform 0.4s cubic-bezier(0.22, 0.61, 0.36, 1);
    }

    .is-labelled a {
      width: auto;
      padding: 0 20px 0 18px;
    }

    svg {
      width: 19px;
      height: 19px;
      fill: none;
      stroke: currentColor;
      stroke-width: 1.5;
      stroke-linecap: round;
      stroke-linejoin: round;
    }

    span {
      font-size: 12px;
      letter-spacing: 0.14em;
      text-transform: uppercase;
    }

    a:hover,
    a:focus-visible {
      border-color: transparent;
      background: linear-gradient(115deg, #d8c7a3 0%, #b99b72 52%, #8c6c45 100%);
      color: #17110a;
      transform: translateY(-3px);
    }
  `,
})
export class SocialLinksComponent {
  protected readonly site = inject(SiteApi);

  readonly labelled = input(false);
  readonly label = input('');

  protected mark(key: string): string {
    return MARKS[key] ?? '';
  }
}
