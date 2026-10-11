import { useFocusTrap } from '../../components/Sheet';

/** Look-alike of the iOS notification permission alert. Labelled as simulated; no browser permission is requested. */
export function SimulatedPermissionPrompt({ open, onResult }: { open: boolean; onResult(granted: boolean): void }) {
  if (!open) return null;
  return <PromptBody onResult={onResult} />;
}

function PromptBody({ onResult }: { onResult(granted: boolean): void }) {
  const ref = useFocusTrap(() => onResult(false));
  return (
    <div className="dialog-backdrop">
      <div className="dialog dialog--system" role="alertdialog" aria-modal="true" aria-labelledby="perm-title" aria-describedby="perm-msg" ref={ref}>
        <span className="dialog__sim-tag">Simulated iOS prompt</span>
        <div className="dialog__text">
          <h2 id="perm-title" className="t-headline">
            “LeafLoom” Would Like to Send You Notifications
          </h2>
          <p id="perm-msg" className="t-footnote">
            Notifications may include alerts, sounds and icon badges. These can be configured in Settings.
          </p>
        </div>
        <div className="dialog__actions dialog__actions--row">
          <button type="button" className="dialog__btn" onClick={() => onResult(false)}>
            Don’t Allow
          </button>
          <button type="button" className="dialog__btn dialog__btn--primary" onClick={() => onResult(true)} data-autofocus>
            Allow
          </button>
        </div>
      </div>
    </div>
  );
}
