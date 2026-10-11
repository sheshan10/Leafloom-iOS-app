const DAY_MS = 86_400_000;

export const startOfDay = (d: Date) => new Date(d.getFullYear(), d.getMonth(), d.getDate());

export const addDays = (d: Date, days: number) => {
  const r = new Date(d);
  r.setDate(r.getDate() + days);
  return r;
};

/** Monday-based week start, matching the ISO-8601 week used by the native Calendar(identifier: .iso8601). */
export const startOfWeek = (d: Date) => {
  const s = startOfDay(d);
  const weekday = (s.getDay() + 6) % 7;
  return addDays(s, -weekday);
};

export const startOfMonth = (d: Date) => new Date(d.getFullYear(), d.getMonth(), 1);

export const isSameDay = (a: Date, b: Date) => startOfDay(a).getTime() === startOfDay(b).getTime();

/** Whole calendar days from a to b (negative when b is earlier). DST-safe because it rounds. */
export const calendarDaysBetween = (a: Date, b: Date) =>
  Math.round((startOfDay(b).getTime() - startOfDay(a).getTime()) / DAY_MS);

export const toISO = (d: Date) => d.toISOString();

/** yyyy-mm-dd in local time, for <input type="date">. */
export const toDateInput = (iso?: string) => {
  if (!iso) return '';
  const d = new Date(iso);
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${d.getFullYear()}-${m}-${day}`;
};

/** Parses yyyy-mm-dd as local midnight plus an optional hour. */
export const fromDateInput = (value: string, hour = 0) => {
  const [y, m, d] = value.split('-').map(Number);
  if (!y || !m || !d) return undefined;
  return new Date(y, m - 1, d, hour).toISOString();
};

export const formatDate = (iso: string, opts: Intl.DateTimeFormatOptions = { day: 'numeric', month: 'short' }) =>
  new Intl.DateTimeFormat(undefined, opts).format(new Date(iso));

export const formatLongDate = (d: Date) =>
  new Intl.DateTimeFormat(undefined, { weekday: 'long', day: 'numeric', month: 'long' }).format(d);

/** "Today", "Tomorrow", "Yesterday", "in 3 days", "2 days ago". */
export const relativeDay = (iso: string, now = new Date()) => {
  const diff = calendarDaysBetween(now, new Date(iso));
  if (diff === 0) return 'Today';
  if (diff === 1) return 'Tomorrow';
  if (diff === -1) return 'Yesterday';
  return diff > 0 ? `in ${diff} days` : `${-diff} days ago`;
};

export const greeting = (d: Date) => {
  const h = d.getHours();
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
};
