/** Presentation copy. Entity fields follow the public database tables. */
export type Lang = 'ar' | 'en';

export type ProjectStatus = 'planning' | 'in_progress' | 'completed';
export type ContactStatus = 'new' | 'read';

export interface ProjectCategory {
  id: number;
  name: string;
  slug: string;
  description: string | null;
  is_active: boolean;
}

export interface ProjectImage {
  id: number;
  image_path: string;
  image_url?: string | null;
  alt_text: string | null;
}

export interface Service {
  id: number;
  name: string;
  slug: string;
  short_description: string | null;
  description: string | null;
  icon: string | null;
  image_url: string | null;
  is_active: boolean | number | string;
}

export interface Project {
  id: number;
  category_id: number;
  title: string;
  slug: string;
  short_description: string | null;
  description: string | null;
  location: string | null;
  area: number | string | null;
  year: number | string | null;
  status: ProjectStatus;
  cover_image: string | null;
  is_featured: boolean | number | string;
  published_at: string | null;
  category: ProjectCategory | null;
  images: ProjectImage[];
  services: Service[];
}

export interface Testimonial {
  id: number;
  project_id: number | null;
  client_name: string;
  content: string;
  rating: number;
}

export interface TeamMember {
  id: number;
  name: string;
  job_title: string;
  bio: string | null;
  image: string | null;
  image_url: string | null;
  is_active: boolean | number | string;
}

export interface ContactMessage {
  name: string;
  email: string;
  phone: string | null;
  subject: string;
  message: string;
  status: ContactStatus;
}

export interface Setting {
  key: string;
  value: string | null;
  type: string;
}

export function setting(settings: Setting[], key: string): string {
  return settings.find((item) => item.key === key)?.value ?? '';
}

export function telHref(phone: string): string {
  return `tel:${phone.replace(/[^\d+]/g, '')}`;
}

export function whatsappHref(number: string): string {
  return `https://wa.me/${number.replace(/\D/g, '')}`;
}

export function gmailHref(email: string): string {
  return `https://mail.google.com/mail/?view=cm&fs=1&to=${encodeURIComponent(email)}`;
}

export function paragraphs(text: string | null): string[] {
  return (text ?? '').split(/\n\n+/).map((part) => part.trim()).filter(Boolean);
}

export interface NavItem {
  id: string;
  label: string;
  href?: string;
}

export interface SiteContent {
  metaTitle: string;
  metaDescription: string;
  skip: string;
  navLabel: string;
  menuOpen: string;
  menuClose: string;
  langLabel: string;
  langSwitch: string;
  whatsappLabel: string;
  nav: NavItem[];
  hero: {
    label: string;
    scroll: string;
    imageAlt: string;
  };
  about: {
    eyebrow: string;
    title: string;
    lede: string;
    more: string;
    teamEyebrow: string;
    teamTitle: string;
  };
  services: {
    eyebrow: string;
    title: string;
    lede: string;
    more: string;
    empty: string;
  };
  projects: {
    eyebrow: string;
    title: string;
    lede: string;
    more: string;
    empty: string;
  };
  why: {
    eyebrow: string;
    title: string;
    items: { index: string; name: string; text: string }[];
  };
  contact: {
    eyebrow: string;
    title: string;
    note: string;
    name: string;
    email: string;
    phone: string;
    subject: string;
    message: string;
    send: string;
    sent: string;
    invalid: string;
    failed: string;
  };
  footer: {
    blurb: string;
    rights: string;
    navLabel: string;
  };
  aboutPage: {
    metaTitle: string;
    metaDescription: string;
    eyebrow: string;
    title: string;
    lede: string;
    storyEyebrow: string;
    storyTitle: string;
    story: string[];
    visionEyebrow: string;
    vision: string;
    missionEyebrow: string;
    mission: string;
    valuesEyebrow: string;
    valuesTitle: string;
    values: { index: string; name: string; text: string }[];
    fieldsEyebrow: string;
    fieldsTitle: string;
    fieldsLede: string;
    teamEyebrow: string;
    teamTitle: string;
    nextTitle: string;
    projects: string;
    contact: string;
  };
  servicesPage: {
    metaTitle: string;
    metaDescription: string;
    eyebrow: string;
    title: string;
    lede: string;
    empty: string;
    nextTitle: string;
    projects: string;
    contact: string;
  };
  projectsPage: {
    metaTitle: string;
    metaDescription: string;
    eyebrow: string;
    title: string;
    lede: string;
    filterLabel: string;
    all: string;
    empty: string;
    nextTitle: string;
    contact: string;
    detail: {
      back: string;
      locationLabel: string;
      yearLabel: string;
      areaLabel: string;
      areaUnit: string;
      servicesEyebrow: string;
      servicesTitle: string;
      galleryEyebrow: string;
      previous: string;
      next: string;
      reviewsEyebrow: string;
      reviewsTitle: string;
      reviewsEmpty: string;
      rateLabel: string;
      dialogTitle: string;
      name: string;
      email: string;
      review: string;
      consent: string;
      send: string;
      close: string;
      thanks: string;
      missingTitle: string;
      missing: string;
      invalid: string;
      failed: string;
      emailTaken: string;
    };
  };
}

export const CONTENT: Record<Lang, SiteContent> = {
  ar: {
    metaTitle: 'أفق إمبريوم | مكتب هندسي',
    metaDescription:
      'مكتب أفق إمبريوم للهندسة والعمارة والتصميم الداخلي والإنشاء والإشراف على الموقع.',
    skip: 'تخطّي إلى المحتوى',
    navLabel: 'التنقل الرئيسي',
    menuOpen: 'فتح القائمة',
    menuClose: 'إغلاق القائمة',
    langLabel: 'التبديل إلى الإنجليزية',
    langSwitch: 'EN',
    whatsappLabel: 'تواصل عبر واتساب',
    nav: [
      { id: 'about', label: 'عن المكتب', href: '/about' },
      { id: 'services', label: 'الخدمات', href: '/services' },
      { id: 'projects', label: 'المشاريع', href: '/projects' },
      { id: 'contact', label: 'تواصل' },
    ],
    hero: {
      label: 'أفق إمبريوم',
      scroll: 'الانتقال إلى القسم التالي',
      imageAlt: 'واجهة معمارية فاتحة في ضوء العصر',
    },
    about: {
      eyebrow: 'عن المكتب',
      title: 'ممارسة قائمة على الضوء والإنشاء والاستعمال.',
      lede: 'تصمّم أفق إمبريوم وتسلّم أعمالاً سكنية وتجارية. العمارة، والتصميم الداخلي، والتنفيذ، والإشراف في مكتب واحد، فيبقى الرسم والبناء على وفاق.',
      more: 'المزيد عن المكتب',
      teamEyebrow: 'الفريق',
      teamTitle: 'من يعمل في المكتب.',
    },
    services: {
      eyebrow: 'الخدمات',
      title: 'ما يتولاه المكتب.',
      lede: 'من المخطط الأول حتى الموقع.',
      more: 'كل الخدمات',
      empty: 'لا خدمات منشورة بعد.',
    },
    projects: {
      eyebrow: 'مشاريع مختارة',
      title: 'أعمال يمكن النظر إليها بهدوء.',
      lede: 'المشاريع المميزة من السكن والتجارة والتصميم الداخلي.',
      more: 'كل المشاريع',
      empty: 'لا مشاريع مميزة بعد.',
    },
    why: {
      eyebrow: 'لماذا نحن',
      title: 'طريقة عمل موزونة.',
      items: [
        { index: '01', name: 'مكتب واحد', text: 'الرسم والتنفيذ والتسليم عند الفريق نفسه.' },
        { index: '02', name: 'أعمال يمكن رؤيتها', text: 'المشاريع السابقة معروضة بوضوح قبل أي قرار.' },
        { index: '03', name: 'ثلاثة أنواع من الطلب', text: 'سكني، وتجاري، وداخلي.' },
        { index: '04', name: 'إشراف على الموقع', text: 'تُراجع الرسمة على البناء، أسبوعاً بعد أسبوع.' },
      ],
    },
    contact: {
      eyebrow: 'تواصل معنا',
      title: 'يستقبل المكتب زوّاره بموعد مسبق.',
      note: 'أفق إمبريوم',
      name: 'الاسم',
      email: 'البريد الإلكتروني',
      phone: 'الهاتف',
      subject: 'الموضوع',
      message: 'الرسالة',
      send: 'إرسال الرسالة',
      sent: 'وصلت الرسالة.',
      invalid: 'أكمل الاسم والبريد والموضوع والرسالة.',
      failed: 'تعذر إرسال الرسالة. حاول مرة أخرى.',
    },
    aboutPage: {
      metaTitle: 'من نحن | أفق إمبريوم',
      metaDescription: 'تعريف بمكتب أفق إمبريوم: تاريخه، ورؤيته، ورسالته، ومجالات عمله.',
      eyebrow: 'من نحن',
      title: 'مكتب واحد، من الرسمة حتى التسليم.',
      lede: 'تعريف بالمكتب: تاريخه، وما يعتمده في العمل، والمجالات التي يتولاها.',
      storyEyebrow: 'النبذة',
      storyTitle: 'العمارة والداخلي والتنفيذ في مكان واحد.',
      story: [
        'تصمّم أفق إمبريوم وتسلّم أعمالاً سكنية وتجارية. يبقى الرسم والتنفيذ والإشراف عند الفريق نفسه، حتى لا ينفصل المخطط عن البناء.',
        'يبدأ العمل من طلب واضح: نوع المشروع، وموقعه، واستعماله. ثم تُراجع الرسمة على الموقع حتى التسليم.',
      ],
      visionEyebrow: 'الرؤية',
      vision: 'فراغ يُفهم قبل أن يُبنى، ويبقى بعد التنفيذ قريباً من الرسمة.',
      missionEyebrow: 'الرسالة',
      mission: 'مرافقة المشروع من الفكرة حتى التسليم، بوضوح في المخطط وحضور في الموقع.',
      valuesEyebrow: 'القيم',
      valuesTitle: 'ما يثبّت العمل.',
      values: [
        { index: '01', name: 'الدقة', text: 'القياس والاستعمال قبل الزخرفة.' },
        { index: '02', name: 'الوضوح', text: 'أعمال سابقة يمكن النظر إليها قبل القرار.' },
        { index: '03', name: 'الاستمرار', text: 'الفريق نفسه من الرسم حتى التسليم.' },
        { index: '04', name: 'العناية بالموقع', text: 'مراجعة التنفيذ أسبوعاً بعد أسبوع.' },
      ],
      fieldsEyebrow: 'مجالات العمل',
      fieldsTitle: 'ما يتسع له المكتب.',
      fieldsLede: 'خبرات في العمارة والتصميم الداخلي والإنشاء والإشراف، للمشاريع السكنية والتجارية.',
      teamEyebrow: 'الفريق',
      teamTitle: 'من يعمل في المكتب.',
      nextTitle: 'للاطلاع على الأعمال، أو لتحديد موعد.',
      projects: 'المشاريع',
      contact: 'تواصل معنا',
    },
    servicesPage: {
      metaTitle: 'الخدمات | أفق إمبريوم',
      metaDescription:
        'خدمات أفق إمبريوم: التصميم المعماري والهندسي والداخلي، الديكور، الإنشاء، الإشراف، الترميم، والتصور ثلاثي الأبعاد.',
      eyebrow: 'الخدمات',
      title: 'ما يُطلب من المكتب، خدمةً خدمة.',
      lede: 'يمكن أخذ خدمة واحدة، أو المسار كاملاً من الرسمة حتى التسليم.',
      empty: 'لا خدمات منشورة بعد.',
      nextTitle: 'للاطلاع على الأعمال، أو لتحديد موعد.',
      projects: 'المشاريع',
      contact: 'تواصل معنا',
    },
    projectsPage: {
      metaTitle: 'المشاريع | أفق إمبريوم',
      metaDescription: 'مشاريع أفق إمبريوم المنجزة: سكنية وتجارية وتصميم داخلي.',
      eyebrow: 'المشاريع',
      title: 'الأعمال المنجزة.',
      lede: 'كل بطاقة تحمل الاسم، والتصنيف، والمكان، والسنة. التفاصيل والصور والخدمات في صفحة المشروع.',
      filterLabel: 'تصنيف المشاريع',
      all: 'الكل',
      empty: 'لا أعمال في هذا التصنيف.',
      nextTitle: 'للحديث عن مشروع، بموعد مسبق.',
      contact: 'تواصل معنا',
      detail: {
        back: 'كل المشاريع',
        locationLabel: 'المكان',
        yearLabel: 'السنة',
        areaLabel: 'المساحة',
        areaUnit: 'م²',
        servicesEyebrow: 'الخدمات',
        servicesTitle: 'ما دخل في هذا المشروع.',
        galleryEyebrow: 'الصور',
        previous: 'الصورة السابقة',
        next: 'الصورة التالية',
        reviewsEyebrow: 'الآراء',
        reviewsTitle: 'رأي في هذا المشروع.',
        reviewsEmpty: 'لا آراء منشورة بعد.',
        rateLabel: 'التقييم من خمس نجوم',
        dialogTitle: 'اكتب رأيك',
        name: 'الاسم',
        email: 'البريد الإلكتروني',
        review: 'نص الرأي',
        consent: 'أوافق على نشر الاسم ونص الرأي مع هذا المشروع.',
        send: 'إرسال الرأي',
        close: 'إغلاق',
        thanks: 'ظهر رأيك مع المشروع.',
        missingTitle: 'المشروع غير موجود',
        missing: 'هذا المشروع غير موجود في القائمة.',
        invalid: 'أكمل الاسم والبريد ونص الرأي، ووافق على النشر.',
        failed: 'تعذر إرسال الرأي. حاول مرة أخرى.',
        emailTaken: 'هذا البريد سجّل رأياً في هذا المشروع.',
      },
    },
    footer: {
      blurb: 'عمارة، وتصميم داخلي، وإنشاء.',
      rights: 'أفق إمبريوم. جميع الحقوق محفوظة.',
      navLabel: 'تذييل الصفحة',
    },
  },
  en: {
    metaTitle: 'UFUQ Imperium | Engineering Office',
    metaDescription:
      'UFUQ Imperium is an engineering office for architecture, interiors, construction, and site supervision.',
    skip: 'Skip to content',
    navLabel: 'Primary',
    menuOpen: 'Open menu',
    menuClose: 'Close menu',
    langLabel: 'Switch to Arabic',
    langSwitch: 'AR',
    whatsappLabel: 'Chat on WhatsApp',
    nav: [
      { id: 'about', label: 'About', href: '/about' },
      { id: 'services', label: 'Services', href: '/services' },
      { id: 'projects', label: 'Projects', href: '/projects' },
      { id: 'contact', label: 'Contact' },
    ],
    hero: {
      label: 'UFUQ Imperium',
      scroll: 'Scroll to the next section',
      imageAlt: 'A pale architectural facade in warm afternoon light',
    },
    about: {
      eyebrow: 'About the office',
      title: 'A practice built on light, structure, and use.',
      lede: 'UFUQ Imperium designs and delivers residential and commercial work. Architecture, interiors, construction, and site supervision sit in one office, so the drawing and the building stay in step.',
      more: 'More about the office',
      teamEyebrow: 'The team',
      teamTitle: 'People in the office.',
    },
    services: {
      eyebrow: 'Services',
      title: 'What the office takes on.',
      lede: 'From the first plan to the site.',
      more: 'All services',
      empty: 'No published services yet.',
    },
    projects: {
      eyebrow: 'Selected work',
      title: 'Projects, set out to be looked at slowly.',
      lede: 'Featured residential, commercial, and interior work.',
      more: 'All projects',
      empty: 'No featured projects yet.',
    },
    why: {
      eyebrow: 'Why us',
      title: 'A measured way of working.',
      items: [
        { index: '01', name: 'One office', text: 'Sketch, construction, and handover stay with the same team.' },
        { index: '02', name: 'Work you can see', text: 'Earlier projects are set out clearly, before any decision.' },
        { index: '03', name: 'Three kinds of brief', text: 'Residential, commercial, and interior.' },
        { index: '04', name: 'Site supervision', text: 'The drawing is checked against the building, week by week.' },
      ],
    },
    contact: {
      eyebrow: 'Contact us',
      title: 'The office receives visitors by appointment.',
      note: 'UFUQ Imperium',
      name: 'Name',
      email: 'Email',
      phone: 'Phone',
      subject: 'Subject',
      message: 'Message',
      send: 'Send the message',
      sent: 'The message has arrived.',
      invalid: 'Add your name, email, subject, and message.',
      failed: 'The message could not be sent. Try again.',
    },
    aboutPage: {
      metaTitle: 'About | UFUQ Imperium',
      metaDescription: 'The UFUQ Imperium office: its history, vision, mission, and fields of work.',
      eyebrow: 'About',
      title: 'One office, from drawing to handover.',
      lede: 'The practice, its history, the way it works, and the fields it takes on.',
      storyEyebrow: 'The practice',
      storyTitle: 'Architecture, interiors, and construction in one office.',
      story: [
        'UFUQ Imperium designs and delivers residential and commercial work. Drawing, construction, and supervision stay with the same team, so the plan and the building do not part company.',
        'The work begins with a clear brief: the kind of project, its place, and its use. The drawing is then checked on site until handover.',
      ],
      visionEyebrow: 'Vision',
      vision: 'A room understood before it is built, and still close to the drawing after it is finished.',
      missionEyebrow: 'Mission',
      mission: 'To stay with a project from the first idea to handover, with a clear plan and a presence on site.',
      valuesEyebrow: 'Values',
      valuesTitle: 'What holds the work.',
      values: [
        { index: '01', name: 'Measure', text: 'Use and dimension before ornament.' },
        { index: '02', name: 'Clarity', text: 'Earlier work can be looked at before a decision.' },
        { index: '03', name: 'Continuity', text: 'The same team, from drawing to handover.' },
        { index: '04', name: 'The site', text: 'Construction reviewed week by week.' },
      ],
      fieldsEyebrow: 'Fields of work',
      fieldsTitle: 'What the office can hold.',
      fieldsLede: 'Architecture, interiors, construction, and supervision, for residential and commercial briefs.',
      teamEyebrow: 'The team',
      teamTitle: 'People in the office.',
      nextTitle: 'To look through the work, or to arrange a visit.',
      projects: 'Projects',
      contact: 'Contact us',
    },
    servicesPage: {
      metaTitle: 'Services | UFUQ Imperium',
      metaDescription:
        'UFUQ Imperium services: architectural, engineering, and interior design, decoration, construction, supervision, restoration, and three-dimensional views.',
      eyebrow: 'Services',
      title: 'What can be asked of the office, service by service.',
      lede: 'A single service can be taken, or the whole path from drawing to handover.',
      empty: 'No published services yet.',
      nextTitle: 'To look through the work, or to arrange a visit.',
      projects: 'Projects',
      contact: 'Contact us',
    },
    projectsPage: {
      metaTitle: 'Projects | UFUQ Imperium',
      metaDescription: 'Completed work by UFUQ Imperium: residential, commercial, and interior projects.',
      eyebrow: 'Projects',
      title: 'Completed work.',
      lede: 'Each card carries the name, the category, the place, and the year. Description, images, and services sit on the project page.',
      filterLabel: 'Project categories',
      all: 'All',
      empty: 'No work in this category.',
      nextTitle: 'To talk about a project, by appointment.',
      contact: 'Contact us',
      detail: {
        back: 'All projects',
        locationLabel: 'Place',
        yearLabel: 'Year',
        areaLabel: 'Area',
        areaUnit: 'm²',
        servicesEyebrow: 'Services',
        servicesTitle: 'What this project included.',
        galleryEyebrow: 'Images',
        previous: 'Previous image',
        next: 'Next image',
        reviewsEyebrow: 'Reviews',
        reviewsTitle: 'A note on this project.',
        reviewsEmpty: 'No published reviews yet.',
        rateLabel: 'Rating out of five stars',
        dialogTitle: 'Write your review',
        name: 'Name',
        email: 'Email',
        review: 'Review',
        consent: 'I agree to publish my name and this review with the project.',
        send: 'Send the review',
        close: 'Close',
        thanks: 'Your review is now with the project.',
        missingTitle: 'Project not found',
        missing: 'This project is not in the list.',
        invalid: 'Add your name, email, and review, and agree to publish it.',
        failed: 'The review could not be sent. Try again.',
        emailTaken: 'This email has already reviewed this project.',
      },
    },
    footer: {
      blurb: 'Architecture, interiors, and construction.',
      rights: 'UFUQ Imperium. All rights reserved.',
      navLabel: 'Footer',
    },
  },
};
