import { useId } from 'react';
import { useFocusTrap } from './Sheet';

interface Props {
  open: boolean;
  title: string;
  message: string;
  confirmLabel: string;
  destructive?: boolean;
  onConfirm(): void;
  onCancel(): void;
}

/** Mirrors SwiftUI `.confirmationDialog`. Focus starts on Cancel to prevent accidental destructive actions. */
export function ConfirmDialog(props: Props) {
  if (!props.open) return null;
  return <ConfirmDialogContent {...props} />;
}

function ConfirmDialogContent({ title, message, confirmLabel, destructive = true, onConfirm, onCancel }: Props) {
  const titleId = useId();
  const msgId = useId();
  const ref = useFocusTrap(onCancel);
  return (
    <div className="dialog-backdrop" onMouseDown={(e) => e.target === e.currentTarget && onCancel()}>
      <div className="dialog" role="alertdialog" aria-modal="true" aria-labelledby={titleId} aria-describedby={msgId} ref={ref}>
        <div className="dialog__text">
          <h2 id={titleId} className="t-headline">
            {title}
          </h2>
          <p id={msgId} className="t-footnote t-secondary">
            {message}
          </p>
        </div>
        <div className="dialog__actions">
          <button type="button" className={`dialog__btn ${destructive ? 'dialog__btn--danger' : 'dialog__btn--primary'}`} onClick={onConfirm}>
            {confirmLabel}
          </button>
          <button type="button" className="dialog__btn" onClick={onCancel} data-autofocus>
            Cancel
          </button>
        </div>
      </div>
    </div>
  );
}
