import type { ReactNode } from 'react';
import { AlertTriangle, CalendarClock, CheckCircle2, Clock, FlaskConical, type LucideIcon } from 'lucide-react';
import type { CareStatus } from '../utils/recurrence';

type Tone = 'success' | 'danger' | 'amber' | 'info' | 'neutral';

const statusMeta: Record<CareStatus, { label: string; tone: Tone; icon: LucideIcon }> = {
  completed: { label: 'Done', tone: 'success', icon: CheckCircle2 },
  overdue: { label: 'Overdue', tone: 'danger', icon: AlertTriangle },
  dueToday: { label: 'Due today', tone: 'amber', icon: Clock },
  upcoming: { label: 'Upcoming', tone: 'info', icon: CalendarClock },
};

/** Always pairs colour with an icon and text so status never relies on colour alone. */
export function StatusBadge({ status }: { status: CareStatus }) {
  const m = statusMeta[status];
  const Icon = m.icon;
  return (
    <span className={`badge badge--${m.tone}`}>
      <Icon size={13} aria-hidden />
      {m.label}
    </span>
  );
}

export function Badge({ tone = 'neutral', icon: Icon, children }: { tone?: Tone; icon?: LucideIcon; children: ReactNode }) {
  return (
    <span className={`badge badge--${tone}`}>
      {Icon && <Icon size={13} aria-hidden />}
      {children}
    </span>
  );
}

export function SampleBadge() {
  return (
    <Badge tone="neutral" icon={FlaskConical}>
      Sample
    </Badge>
  );
}
