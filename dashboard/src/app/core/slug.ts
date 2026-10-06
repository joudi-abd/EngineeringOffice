export function slugify(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .replace(/[\s_]+/g, '-')
    .replace(/[^\p{L}\p{N}-]+/gu, '')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');
}

export function recordSlug(label: string, existing = ''): string {
  const current = existing.trim();
  if (current) return current;
  const base = slugify(label).slice(0, 240);
  const stamp = Date.now().toString(36);
  return `${base || 'item'}-${stamp}`;
}
