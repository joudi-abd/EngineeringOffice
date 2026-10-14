import { Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { errorText } from '../../core/api.service';
import { AuthService } from '../../core/auth.service';
import { ThemeToggleComponent } from '../../layout/theme-toggle.component';

type LoginMode = 'login' | 'forgot' | 'reset';

@Component({
  selector: 'app-login',
  imports: [ReactiveFormsModule, ThemeToggleComponent],
  templateUrl: './login.component.html',
})
export class LoginComponent {
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);
  private readonly formBuilder = inject(FormBuilder);

  protected readonly mode = signal<LoginMode>('login');
  protected readonly error = signal('');
  protected readonly notice = signal('');
  protected readonly busy = signal(false);
  protected readonly form = this.formBuilder.nonNullable.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', Validators.required],
    code: ['', [Validators.required, Validators.pattern(/^\d{6}$/)]],
    nextPassword: ['', [Validators.required, Validators.minLength(8)]],
    confirmPassword: ['', Validators.required],
  });

  protected submit(): void {
    if (this.mode() === 'forgot') {
      this.requestCode();
      return;
    }
    if (this.mode() === 'reset') {
      this.resetPassword();
      return;
    }
    this.login();
  }

  protected showForgot(): void {
    this.mode.set('forgot');
    this.error.set('');
    this.notice.set('');
  }

  protected showLogin(): void {
    this.mode.set('login');
    this.error.set('');
    this.notice.set('');
  }

  private login(): void {
    const { email, password } = this.form.getRawValue();
    if (this.form.controls.email.invalid || this.form.controls.password.invalid) {
      this.form.controls.email.markAsTouched();
      this.form.controls.password.markAsTouched();
      this.error.set('أدخل البريد وكلمة المرور.');
      return;
    }
    this.busy.set(true);
    this.error.set('');
    this.auth.login(email.trim(), password).subscribe({
      next: () => void this.router.navigate(['/']),
      error: (error: unknown) => {
        this.busy.set(false);
        this.error.set(errorText(error));
      },
    });
  }

  private requestCode(): void {
    const email = this.form.controls.email.getRawValue().trim();
    if (this.form.controls.email.invalid) {
      this.form.controls.email.markAsTouched();
      this.error.set('أدخل بريداً صالحاً.');
      return;
    }
    this.busy.set(true);
    this.error.set('');
    this.auth.forgotPassword(email).subscribe({
      next: () => {
        this.busy.set(false);
        this.mode.set('reset');
        this.notice.set('إذا كان الحساب موجوداً ونشطاً، سيصلك رمز خلال دقائق. صلاحيته 10 دقائق.');
      },
      error: (error: unknown) => {
        this.busy.set(false);
        this.error.set(errorText(error));
      },
    });
  }

  private resetPassword(): void {
    const { email, code, nextPassword, confirmPassword } = this.form.getRawValue();
    if (this.form.controls.email.invalid || this.form.controls.code.invalid || this.form.controls.nextPassword.invalid) {
      this.error.set('أدخل البريد ورمزاً من 6 أرقام وكلمة مرور من 8 أحرف على الأقل.');
      return;
    }
    if (nextPassword !== confirmPassword) {
      this.error.set('تأكيد كلمة المرور غير مطابق.');
      return;
    }
    this.busy.set(true);
    this.error.set('');
    this.auth.resetPassword(email.trim(), code.trim(), nextPassword, confirmPassword).subscribe({
      next: () => {
        this.busy.set(false);
        this.form.controls.password.setValue('');
        this.form.controls.code.setValue('');
        this.form.controls.nextPassword.setValue('');
        this.form.controls.confirmPassword.setValue('');
        this.mode.set('login');
        this.notice.set('تم تغيير كلمة المرور. سجّل الدخول الآن.');
      },
      error: (error: unknown) => {
        this.busy.set(false);
        this.error.set(errorText(error));
      },
    });
  }
}
