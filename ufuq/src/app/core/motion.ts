/**
 * Small motion layer: scroll-reveal for content blocks, plus two CSS variables on <html>
 * (`--sy` scroll offset in px, `--p` page progress 0..1) used for parallax and the progress line.
 * Content stays fully visible when JavaScript is off or the user prefers reduced motion.
 */
const TEXT_TARGETS = [
  'main .kicker',
  'main .display',
  'main .lede',
  'main .text-link',
  'main .quiet',
  'main .index-list li',
  'main .points li',
  'main .fields__list li',
  'main .catalogue li',
  'main .member',
  'main dl > div',
  'main .comment',
  'main .videos li',
  'main .services li',
  'main .contact__phone',
  'main .contact__ways',
  'main .contact__form',
  'main .filters',
  'main .rate',
  'main .next__links',
].join(',');

const IMAGE_TARGETS = ['main .shot', 'main .archive figure', 'main .mosaic'].join(',');

export function startMotion(): () => void {
  const root = document.documentElement;
  const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  let frame = 0;
  const measure = () => {
    frame = 0;
    const y = window.scrollY;
    const max = Math.max(1, root.scrollHeight - window.innerHeight);
    root.style.setProperty('--sy', String(Math.round(y)));
    root.style.setProperty('--p', Math.min(1, y / max).toFixed(4));
  };
  const onScroll = () => {
    if (!frame) frame = requestAnimationFrame(measure);
  };
  window.addEventListener('scroll', onScroll, { passive: true });
  window.addEventListener('resize', onScroll, { passive: true });
  measure();

  if (reduced || !('IntersectionObserver' in window)) {
    return () => {
      window.removeEventListener('scroll', onScroll);
      window.removeEventListener('resize', onScroll);
    };
  }

  const seen = new WeakSet<Element>();
  const io = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        entry.target.classList.add('is-in');
        io.unobserve(entry.target);
      }
    },
    { rootMargin: '0px 0px -8% 0px', threshold: 0 },
  );

  const mark = (el: Element, className: 'rv' | 'rv-img') => {
    if (seen.has(el)) return;
    seen.add(el);
    if (el.parentElement?.closest('.rv, .rv-img')) return;
    const parent = el.parentElement;
    const index = parent ? Array.prototype.indexOf.call(parent.children, el) : 0;
    (el as HTMLElement).style.setProperty('--d', `${Math.min(Math.max(index, 0), 5) * 90}ms`);
    el.classList.add(className);
    io.observe(el);
  };

  const scan = () => {
    document.querySelectorAll(IMAGE_TARGETS).forEach((el) => mark(el, 'rv-img'));
    document.querySelectorAll(TEXT_TARGETS).forEach((el) => mark(el, 'rv'));
  };

  let scheduled = 0;
  const mutations = new MutationObserver(() => {
    if (scheduled) return;
    scheduled = requestAnimationFrame(() => {
      scheduled = 0;
      scan();
    });
  });
  mutations.observe(document.body, { childList: true, subtree: true });
  scan();

  return () => {
    io.disconnect();
    mutations.disconnect();
    window.removeEventListener('scroll', onScroll);
    window.removeEventListener('resize', onScroll);
  };
}
