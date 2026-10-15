import { Lang } from './site-content';

export interface ProfileCopy {
  metaTitle: string;
  metaDescription: string;
  eyebrow: string;
  lede: string;
  details: {
    title: string;
    firstName: string;
    lastName: string;
    email: string;
    emailStatus: string;
    phone: string;
    google: string;
    linked: string;
    notLinked: string;
    memberSince: string;
    lastLogin: string;
    verified: string;
    unverified: string;
    empty: string;
    editNote: string;
    contact: string;
  };
  security: {
    title: string;
    lede: string;
    send: string;
    resend: string;
    resendIn: string;
    sent: string;
    code: string;
    password: string;
    confirm: string;
    hint: string;
    save: string;
  };
  done: {
    title: string;
    text: string;
    home: string;
  };
  signOut: string;
  home: string;
}

export const PROFILE_COPY: Record<Lang, ProfileCopy> = {
  ar: {
    metaTitle: 'حسابي | أفق إمبريوم',
    metaDescription: 'بيانات حسابك في أفق إمبريوم وإعدادات كلمة المرور.',
    eyebrow: 'حسابي',
    lede: 'هذه بيانات حسابك كما سجّلتها. يمكنك من هنا تغيير كلمة المرور أو تسجيل الخروج.',
    details: {
      title: 'بيانات الحساب',
      firstName: 'الاسم الأول',
      lastName: 'الاسم الثاني',
      email: 'البريد الإلكتروني',
      emailStatus: 'حالة البريد',
      phone: 'الهاتف',
      google: 'حساب Google',
      linked: 'مربوط',
      notLinked: 'غير مربوط',
      memberSince: 'عضو منذ',
      lastLogin: 'آخر دخول',
      verified: 'مؤكَّد',
      unverified: 'غير مؤكَّد',
      empty: 'غير مسجّل',
      editNote: 'لتعديل الاسم أو الهاتف أو البريد، راسلنا من صفحة التواصل وسنعدّلها لك.',
      contact: 'تواصل معنا',
    },
    security: {
      title: 'كلمة المرور',
      lede: 'سنرسل رمزاً إلى بريدك لتعيين كلمة مرور جديدة. بعد الحفظ تُغلَق جلساتك كلها، وتسجّل الدخول بها من جديد.',
      send: 'أرسل الرمز إلى بريدي',
      resend: 'إعادة إرسال الرمز',
      resendIn: 'يمكنك إعادة الإرسال بعد {s} ثانية.',
      sent: 'أرسلنا الرمز إلى بريدك.',
      code: 'رمز الاستعادة',
      password: 'كلمة المرور الجديدة',
      confirm: 'تأكيد كلمة المرور',
      hint: '8 أحرف على الأقل.',
      save: 'حفظ كلمة المرور',
    },
    done: {
      title: 'تم تغيير كلمة المرور',
      text: 'أُغلقت جلساتك على هذا الجهاز. سجّل الدخول بكلمة المرور الجديدة عندما تحتاج.',
      home: 'العودة إلى الموقع',
    },
    signOut: 'تسجيل الخروج',
    home: 'العودة إلى الموقع',
  },
  en: {
    metaTitle: 'My account | UFUQ Imperium',
    metaDescription: 'Your UFUQ Imperium account details and password settings.',
    eyebrow: 'My account',
    lede: 'These are your account details as you registered them. From here you can change your password or sign out.',
    details: {
      title: 'Account details',
      firstName: 'First name',
      lastName: 'Second name',
      email: 'Email',
      emailStatus: 'Email status',
      phone: 'Phone',
      google: 'Google account',
      linked: 'Linked',
      notLinked: 'Not linked',
      memberSince: 'Member since',
      lastLogin: 'Last sign-in',
      verified: 'Confirmed',
      unverified: 'Not confirmed',
      empty: 'Not provided',
      editNote: 'To change your name, phone, or email, write to us from the contact page and we will update it for you.',
      contact: 'Contact us',
    },
    security: {
      title: 'Password',
      lede: 'We will send a code to your email to set a new password. After saving, all your sessions are closed and you sign in again with it.',
      send: 'Send the code to my email',
      resend: 'Send the code again',
      resendIn: 'You can send it again in {s} seconds.',
      sent: 'We sent the code to your email.',
      code: 'Reset code',
      password: 'New password',
      confirm: 'Confirm password',
      hint: 'At least 8 characters.',
      save: 'Save password',
    },
    done: {
      title: 'Your password was changed',
      text: 'Your sessions on this device were closed. Sign in with the new password whenever you need.',
      home: 'Back to the site',
    },
    signOut: 'Sign out',
    home: 'Back to the site',
  },
};
