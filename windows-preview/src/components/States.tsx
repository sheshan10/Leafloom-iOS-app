import { AlertCircle, RefreshCw } from 'lucide-react';
import type { ReactNode } from 'react';
import { SecondaryButton } from './Button';

type Illustration = 'plants' | 'tasks' | 'journal' | 'search' | 'insights';

export function EmptyState({ illustration, title, message, action }: { illustration: Illustration; title: string; message: string; action?: ReactNode }) {
  return (
    <div className="empty-state">
      <img src={`/illustrations/empty-${illustration}.svg`} alt="" aria-hidden className="empty-state__art" />
      <h2 className="t-title3">{title}</h2>
      <p className="t-subhead t-secondary">{message}</p>
      {action && <div className="empty-state__action">{action}</div>}
    </div>
  );
}

export function ErrorState({ title = 'Something went wrong', message, onRetry }: { title?: string; message: string; onRetry?: () => void }) {
  return (
    <div className="error-state" role="alert">
      <span className="error-state__icon">
        <AlertCircle size={28} aria-hidden />
      </span>
      <h2 className="t-title3">{title}</h2>
      <p className="t-subhead t-secondary">{message}</p>
      {onRetry && (
        <SecondaryButton icon={RefreshCw} onClick={onRetry}>
          Try again
        </SecondaryButton>
      )}
    </div>
  );
}

/** Animated sprout used for loading and processing states. Animation stops with reduced motion. */
export function LoadingView({ label = 'Loading…', compact }: { label?: string; compact?: boolean }) {
  return (
    <div className={`loading-view ${compact ? 'loading-view--compact' : ''}`} role="status" aria-live="polite">
      <svg viewBox="0 0 64 64" width={compact ? 40 : 64} height={compact ? 40 : 64} aria-hidden className="loading-sprout">
        <path d="M20 52h24l-3 8H23z" fill="var(--brand-terracotta)" />
        <g className="loading-sprout__stem">
          <path d="M32 52V30" stroke="var(--color-primary)" strokeWidth="3" strokeLinecap="round" />
          <path className="loading-sprout__leaf-l" d="M32 38c-9 0-13-6-13-12 9 0 13 6 13 12z" fill="var(--brand-leaf)" />
          <path className="loading-sprout__leaf-r" d="M32 34c8 0 12-5 12-11-8 0-12 5-12 11z" fill="var(--color-primary)" />
        </g>
      </svg>
      <span className="t-subhead t-secondary">{label}</span>
    </div>
  );
}

export function SkeletonBlock({ height = 16, width = '100%' }: { height?: number; width?: number | string }) {
  return <span className="skeleton" style={{ height, width }} aria-hidden />;
}
