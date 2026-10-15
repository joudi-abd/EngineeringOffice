import { Lang } from './site-content';

/** Why the visitor is being asked to sign in. Shown at the top of the sign-in window. */
export type AuthReason = 'message' | 'review' | 'profile';

/** Every way a sign-in step can fail. Each one has a sentence in both languages below. */
export type AuthErrorKey =
  | 'invalid'
  | 'email'
  | 'passwordShort'
  | 'passwordMismatch'
  | 'badCredentials'
  | 'inactive'
  | 'emailTaken'
  | 'phoneTaken'
  | 'phoneInvalid'
  | 'codeWrong'
  | 'codeExpired'
  | 'codeAttempts'
  | 'codeMissing'
  | 'wait'
  | 'tooMany'
  | 'mailFailed'
  | 'network'
  | 'failed'
  | 'google'
  | 'googleBlocked'
  | 'googleOwner'
  | 'googleConflict'
  | 'googleVerify'
  | 'googleUnavailable'
  | 'googleDomain';

export interface AuthCopy {
  close: string;
  showPassword: string;
  hidePassword: string;
  or: string;
  google: string;
  reasons: Record<AuthReason, string>;
  login: {
    title: string;
    email: string;
    password: string;
    submit: string;
    forgot: string;
    noAccount: string;
    create: string;
  };
  register: {
    title: string;
    firstName: string;
    lastName: string;
    email: string;
    phone: string;
    password: string;
    confirm: string;
    hint: string;
    submit: string;
    haveAccount: string;
    signIn: string;
  };
  verify: {
    title: string;
    lede: string;
    code: string;
    submit: string;
    resend: string;
    resendIn: string;
    back: string;
  };
  forgot: {
    title: string;
    lede: string;
    submit: string;
    back: string;
  };
  reset: {
    title: string;
    lede: string;
    code: string;
    password: string;
    confirm: string;
    submit: string;
  };
  notices: {
    verified: string;
    resetDone: string;
    codeSent: string;
    resent: string;
    needsVerify: string;
  };
  errors: Record<AuthErrorKey, string>;
  account: {
    signOut: string;
    signedInAs: string;
    profile: string;
    signIn: string;
  };
}

export const AUTH_COPY: Record<Lang, AuthCopy> = {
  ar: {
    close: 'إغلاق',
    showPassword: 'إظهار كلمة المرور',
    hidePassword: 'إخفاء كلمة المرور',
    or: 'أو',
    google: 'المتابعة باستخدام Google',
    reasons: {
      message: 'سجّل الدخول لإرسال رسالتك. ما كتبته محفوظ.',
      review: 'سجّل الدخول لتكتب رأيك في المشروع. تقييمك محفوظ.',
      profile: 'سجّل الدخول لتفتح صفحة حسابك.',
    },
    login: {
      title: 'تسجيل الدخول',
      email: 'البريد الإلكتروني',
      password: 'كلمة المرور',
      submit: 'دخول',
      forgot: 'نسيت كلمة المرور؟',
      noAccount: 'ليس لديك حساب؟',
      create: 'أنشئ حساباً',
    },
    register: {
      title: 'إنشاء حساب',
      firstName: 'الاسم الأول',
      lastName: 'الاسم الثاني',
      email: 'البريد الإلكتروني',
      phone: 'الهاتف',
      password: 'كلمة المرور',
      confirm: 'تأكيد كلمة المرور',
      hint: '8 أحرف على الأقل.',
      submit: 'إنشاء الحساب',
      haveAccount: 'لديك حساب؟',
      signIn: 'سجّل الدخول',
    },
    verify: {
      title: 'تأكيد البريد',
      lede: 'أرسلنا رمزاً من 6 أرقام إلى',
      code: 'رمز التأكيد',
      submit: 'تأكيد',
      resend: 'إعادة إرسال الرمز',
      resendIn: 'يمكنك إعادة الإرسال بعد {s} ثانية.',
      back: 'رجوع',
    },
    forgot: {
      title: 'استعادة كلمة المرور',
      lede: 'اكتب بريدك وسنرسل إليه رمزاً لتعيين كلمة مرور جديدة.',
      submit: 'إرسال الرمز',
      back: 'العودة إلى تسجيل الدخول',
    },
    reset: {
      title: 'كلمة مرور جديدة',
      lede: 'اكتب الرمز الذي وصل إلى بريدك، ثم كلمة المرور الجديدة.',
      code: 'رمز الاستعادة',
      password: 'كلمة المرور الجديدة',
      confirm: 'تأكيد كلمة المرور',
      submit: 'حفظ كلمة المرور',
    },
    notices: {
      verified: 'تم تأكيد البريد.',
      resetDone: 'تم تغيير كلمة المرور. سجّل الدخول بها الآن.',
      codeSent: 'أرسلنا الرمز إلى بريدك.',
      resent: 'أعدنا إرسال الرمز.',
      needsVerify: 'بريدك لم يُؤكَّد بعد. أرسلنا رمزاً جديداً إليه.',
    },
    errors: {
      invalid: 'أكمل الحقول المطلوبة.',
      email: 'اكتب بريداً إلكترونياً صحيحاً.',
      passwordShort: 'كلمة المرور 8 أحرف على الأقل.',
      passwordMismatch: 'كلمتا المرور غير متطابقتين.',
      badCredentials: 'البريد أو كلمة المرور غير صحيحة.',
      inactive: 'هذا الحساب غير مفعّل. تواصل معنا.',
      emailTaken: 'هذا البريد مسجّل مسبقاً. سجّل الدخول.',
      phoneTaken: 'رقم الهاتف مسجّل مسبقاً.',
      phoneInvalid: 'رقم الهاتف غير صالح.',
      codeWrong: 'الرمز غير صحيح.',
      codeExpired: 'انتهت صلاحية الرمز. اطلب رمزاً جديداً.',
      codeAttempts: 'محاولات كثيرة. اطلب رمزاً جديداً.',
      codeMissing: 'لا يوجد رمز لهذا البريد. اطلب رمزاً جديداً.',
      wait: 'انتظر دقيقة قبل طلب رمز جديد.',
      tooMany: 'محاولات كثيرة. حاول بعد دقيقة.',
      mailFailed: 'تعذر إرسال البريد. حاول لاحقاً.',
      network: 'تعذر الاتصال بالخادم. تحقق من الاتصال وحاول مرة أخرى.',
      failed: 'حدث خطأ. حاول مرة أخرى.',
      google: 'تعذر الدخول عبر Google. حاول مرة أخرى.',
      googleBlocked: 'حُجبت نافذة Google. اسمح بالنوافذ المنبثقة وحاول مرة أخرى.',
      googleOwner: 'الدخول عبر Google متاح للعملاء فقط.',
      googleConflict: 'هذا البريد مرتبط بحساب Google آخر.',
      googleVerify: 'أكّد بريدك أولاً، ثم اربط حساب Google.',
      googleUnavailable: 'الدخول عبر Google غير متاح الآن.',
      googleDomain: 'هذا الموقع غير مصرّح له بالدخول عبر Google.',
    },
    account: {
      signOut: 'تسجيل الخروج',
      signedInAs: 'مسجّل باسم',
      profile: 'حسابي',
      signIn: 'تسجيل الدخول',
    },
  },
  en: {
    close: 'Close',
    showPassword: 'Show password',
    hidePassword: 'Hide password',
    or: 'or',
    google: 'Continue with Google',
    reasons: {
      message: 'Sign in to send your message. What you wrote is kept.',
      review: 'Sign in to write your review. Your rating is kept.',
      profile: 'Sign in to open your account page.',
    },
    login: {
      title: 'Sign in',
      email: 'Email',
      password: 'Password',
      submit: 'Sign in',
      forgot: 'Forgot your password?',
      noAccount: 'No account yet?',
      create: 'Create one',
    },
    register: {
      title: 'Create an account',
      firstName: 'First name',
      lastName: 'Second name',
      email: 'Email',
      phone: 'Phone',
      password: 'Password',
      confirm: 'Confirm password',
      hint: 'At least 8 characters.',
      submit: 'Create account',
      haveAccount: 'Already have an account?',
      signIn: 'Sign in',
    },
    verify: {
      title: 'Confirm your email',
      lede: 'We sent a 6-digit code to',
      code: 'Confirmation code',
      submit: 'Confirm',
      resend: 'Send the code again',
      resendIn: 'You can send it again in {s} seconds.',
      back: 'Back',
    },
    forgot: {
      title: 'Reset your password',
      lede: 'Enter your email and we will send a code to set a new password.',
      submit: 'Send the code',
      back: 'Back to sign in',
    },
    reset: {
      title: 'New password',
      lede: 'Enter the code sent to your email, then the new password.',
      code: 'Reset code',
      password: 'New password',
      confirm: 'Confirm password',
      submit: 'Save password',
    },
    notices: {
      verified: 'Your email is confirmed.',
      resetDone: 'Your password was changed. Sign in with it now.',
      codeSent: 'We sent the code to your email.',
      resent: 'We sent the code again.',
      needsVerify: 'Your email is not confirmed yet. We sent a new code to it.',
    },
    errors: {
      invalid: 'Fill in the required fields.',
      email: 'Enter a valid email address.',
      passwordShort: 'The password needs at least 8 characters.',
      passwordMismatch: 'The two passwords do not match.',
      badCredentials: 'The email or password is incorrect.',
      inactive: 'This account is inactive. Contact us.',
      emailTaken: 'This email is already registered. Sign in instead.',
      phoneTaken: 'This phone number is already registered.',
      phoneInvalid: 'The phone number is not valid.',
      codeWrong: 'The code is incorrect.',
      codeExpired: 'The code has expired. Ask for a new one.',
      codeAttempts: 'Too many attempts. Ask for a new code.',
      codeMissing: 'There is no code for this email. Ask for a new one.',
      wait: 'Wait a minute before asking for another code.',
      tooMany: 'Too many attempts. Try again in a minute.',
      mailFailed: 'The email could not be sent. Try again later.',
      network: 'Could not reach the server. Check your connection and try again.',
      failed: 'Something went wrong. Try again.',
      google: 'Google sign-in did not work. Try again.',
      googleBlocked: 'The Google window was blocked. Allow pop-ups and try again.',
      googleOwner: 'Google sign-in is for customers only.',
      googleConflict: 'This email is linked to another Google account.',
      googleVerify: 'Confirm your email first, then link Google.',
      googleUnavailable: 'Google sign-in is not available right now.',
      googleDomain: 'This site is not allowed to use Google sign-in.',
    },
    account: {
      signOut: 'Sign out',
      signedInAs: 'Signed in as',
      profile: 'My account',
      signIn: 'Sign in',
    },
  },
};
