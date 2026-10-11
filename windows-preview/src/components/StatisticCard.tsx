import type { LucideIcon } from 'lucide-react';

export function StatisticCard({ icon: Icon, value, label, tone = 'primary', onClick }: { icon: LucideIcon; value: string | number; label: string; tone?: 'primary' | 'amber' | 'danger' | 'info'; onClick?: () => void }) {
  const content = (
    <>
      <span className={`stat-card__icon stat-card__icon--${tone}`}>
        <Icon size={18} aria-hidden />
      </span>
      <span className="stat-card__value t-numeric">{value}</span>
      <span className="stat-card__label">{label}</span>
    </>
  );
  return onClick ? (
    <button type="button" className="stat-card stat-card--button" onClick={onClick} aria-label={`${value} ${label}`}>
      {content}
    </button>
  ) : (
    <div className="stat-card" aria-label={`${value} ${label}`} role="group">
      {content}
    </div>
  );
}
