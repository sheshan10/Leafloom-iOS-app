import { useEffect, useId, useRef, type ReactNode } from 'react';

const FOCUSABLE = 'button:not([disabled]), [href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])';

/** Keeps keyboard focus inside a modal, restores it on close, and closes on Escape. */
export function useFocusTrap(onEscape: () => void, active = true) {
  const ref = useRef<HTMLDivElement>(null);
  const escapeRef = useRef(onEscape);
  useEffect(() => {
    escapeRef.current = onEscape;
  });
  useEffect(() => {
    if (!active) return;
    const previous = document.activeElement as HTMLElement | null;
    const node = ref.current;
    const first = node?.querySelector<HTMLElement>('[data-autofocus]') ?? node?.querySelector<HTMLElement>(FOCUSABLE);
    first?.focus();
    const onKey = (e: KeyboardEvent) => {
      if (!node) return;
      if (e.key === 'Escape') {
        e.stopPropagation();
        escapeRef.current();
        return;
      }
      if (e.key !== 'Tab') return;
      const items = [...node.querySelectorAll<HTMLElement>(FOCUSABLE)];
      if (items.length === 0) return;
      const firstEl = items[0];
      const lastEl = items[items.length - 1];
      if (e.shiftKey && document.activeElement === firstEl) {
        e.preventDefault();
        lastEl.focus();
      } else if (!e.shiftKey && document.activeElement === lastEl) {
        e.preventDefault();
        firstEl.focus();
      }
    };
    node?.addEventListener('keydown', onKey);
    return () => {
      node?.removeEventListener('keydown', onKey);
      previous?.focus?.();
    };
  }, [active]);
  return ref;
}

interface SheetProps {
  title: string;
  onCancel(): void;
  /** When provided, the trailing button submits the form with this id. */
  formId?: string;
  confirmLabel?: string;
  confirmDisabled?: boolean;
  busy?: boolean;
  children: ReactNode;
}

/** Accessible bottom sheet mirroring a SwiftUI `.sheet` with a NavigationStack toolbar. */
export function Sheet({ title, onCancel, formId, confirmLabel = 'Save', confirmDisabled, busy, children }: SheetProps) {
  const titleId = useId();
  const ref = useFocusTrap(onCancel);
  return (
    <div className="sheet-backdrop" onMouseDown={(e) => e.target === e.currentTarget && onCancel()}>
      <div className="sheet" role="dialog" aria-modal="true" aria-labelledby={titleId} ref={ref}>
        <div className="sheet__grabber" aria-hidden />
        <header className="sheet__header">
          <button type="button" className="sheet__btn" onClick={onCancel}>
            Cancel
          </button>
          <h2 id={titleId} className="sheet__title">
            {title}
          </h2>
          {formId ? (
            <button type="submit" form={formId} className="sheet__btn sheet__btn--confirm" disabled={confirmDisabled || busy}>
              {busy ? 'Saving…' : confirmLabel}
            </button>
          ) : (
            <span className="sheet__btn" aria-hidden />
          )}
        </header>
        <div className="sheet__content">{children}</div>
      </div>
    </div>
  );
}
