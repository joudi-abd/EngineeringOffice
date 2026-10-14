import { Component, computed, input } from '@angular/core';
import { serviceIcon } from '../../core/service-icons';

/** Icon chosen for a service in the dashboard; renders nothing when none is set. */
@Component({
  selector: 'app-service-icon',
  template: `
    @if (path(); as d) {
      <span class="mark" aria-hidden="true">
        <svg viewBox="0 0 24 24"><path [attr.d]="d" /></svg>
      </span>
    }
  `,
  styles: `
    :host {
      display: contents;
    }

    .mark {
      display: inline-grid;
      place-items: center;
      width: 46px;
      height: 46px;
      margin-bottom: 14px;
      border: 1px solid rgba(203, 184, 146, 0.4);
      border-radius: 50%;
      color: var(--gold-soft, #cbb892);
    }

    svg {
      width: 21px;
      height: 21px;
      fill: none;
      stroke: currentColor;
      stroke-width: 1.4;
      stroke-linecap: round;
      stroke-linejoin: round;
    }
  `,
})
export class ServiceIconComponent {
  readonly name = input<string | null | undefined>('');
  protected readonly path = computed(() => serviceIcon(this.name())?.path ?? '');
}
