import { Component, ElementRef, HostListener, forwardRef, inject, input, signal } from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';

export interface SelectOption {
  value: string;
  label: string;
  /** SVG path data (24×24, stroke) shown before the label. */
  icon?: string;
}

/** Themed dropdown that works with both reactive forms and ngModel. */
@Component({
  selector: 'app-select',
  providers: [{ provide: NG_VALUE_ACCESSOR, useExisting: forwardRef(() => SelectComponent), multi: true }],
  template: `
    <button
      class="select__trigger"
      type="button"
      role="combobox"
      aria-haspopup="listbox"
      [attr.aria-expanded]="open()"
      [disabled]="disabled()"
      (click)="toggle()"
      (keydown)="onKey($event)"
    >
      @if (current()?.icon; as icon) {
        <svg class="select__icon" viewBox="0 0 24 24" aria-hidden="true"><path [attr.d]="icon" /></svg>
      }
      <span class="select__label" [class.is-placeholder]="!current()">{{ current()?.label || placeholder() }}</span>
      <svg class="select__chevron" viewBox="0 0 24 24" aria-hidden="true"><path d="M6 9l6 6 6-6" /></svg>
    </button>

    @if (open()) {
      <div class="select__panel" role="listbox">
        @for (option of options(); track option.value; let index = $index) {
          <div
            class="select__option"
            role="option"
            [class.is-selected]="option.value === value()"
            [class.is-active]="index === active()"
            [attr.aria-selected]="option.value === value()"
            (mouseenter)="active.set(index)"
            (click)="pick(option, $event)"
          >
            @if (option.icon) {
              <svg class="select__icon" viewBox="0 0 24 24" aria-hidden="true"><path [attr.d]="option.icon" /></svg>
            }
            <span>{{ option.label }}</span>
            @if (option.value === value()) {
              <svg class="select__tick" viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12.5l4.5 4.5L19 7.5" /></svg>
            }
          </div>
        }
      </div>
    }
  `,
})
export class SelectComponent implements ControlValueAccessor {
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);

  readonly options = input.required<SelectOption[]>();
  readonly placeholder = input('اختر');

  protected readonly value = signal('');
  protected readonly open = signal(false);
  protected readonly active = signal(0);
  protected readonly disabled = signal(false);

  private onChange: (value: string) => void = () => undefined;
  private onTouched: () => void = () => undefined;

  protected current(): SelectOption | null {
    return this.options().find((option) => option.value === this.value()) ?? null;
  }

  writeValue(value: unknown): void {
    this.value.set(value == null ? '' : String(value));
  }

  registerOnChange(fn: (value: string) => void): void {
    this.onChange = fn;
  }

  registerOnTouched(fn: () => void): void {
    this.onTouched = fn;
  }

  setDisabledState(isDisabled: boolean): void {
    this.disabled.set(isDisabled);
  }

  protected toggle(): void {
    if (this.open()) {
      this.close();
      return;
    }
    const index = this.options().findIndex((option) => option.value === this.value());
    this.active.set(Math.max(index, 0));
    this.open.set(true);
    queueMicrotask(() => this.host.nativeElement.querySelector('.is-selected')?.scrollIntoView({ block: 'nearest' }));
  }

  protected pick(option: SelectOption, event?: Event): void {
    // The control sits inside a <label>; stop the click from re-activating the trigger.
    event?.preventDefault();
    event?.stopPropagation();
    this.value.set(option.value);
    this.onChange(option.value);
    this.close();
  }

  protected onKey(event: KeyboardEvent): void {
    const options = this.options();
    if (event.key === 'Escape') return this.close();
    if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
      event.preventDefault();
      if (!this.open()) return this.toggle();
      const step = event.key === 'ArrowDown' ? 1 : -1;
      this.active.update((index) => (index + step + options.length) % options.length);
      this.host.nativeElement.querySelector('.is-active')?.scrollIntoView({ block: 'nearest' });
    } else if ((event.key === 'Enter' || event.key === ' ') && this.open()) {
      event.preventDefault();
      const option = options[this.active()];
      if (option) this.pick(option);
    }
  }

  @HostListener('document:click', ['$event'])
  protected outside(event: Event): void {
    if (this.open() && !this.host.nativeElement.contains(event.target as Node)) this.close();
  }

  private close(): void {
    this.open.set(false);
    this.onTouched();
  }
}
