import { createContext, useCallback, useContext, useMemo, useRef, useState, type ReactNode } from 'react';
import { AlertCircle, BellRing, CheckCircle2, Info } from 'lucide-react';

export type ToastKind = 'success' | 'error' | 'info' | 'reminder';

export interface ToastOptions {
  kind?: ToastKind;
  actionLabel?: string;
  onAction?: () => void;
  durationMs?: number;
}

interface ToastItem extends ToastOptions {
  id: number;
  message: string;
}

const ToastContext = createContext<((message: string, options?: ToastOptions) => void) | null>(null);

const icons = { success: CheckCircle2, error: AlertCircle, info: Info, reminder: BellRing };

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<ToastItem[]>([]);
  const nextId = useRef(1);

  const dismiss = useCallback((id: number) => setToasts((t) => t.filter((x) => x.id !== id)), []);

  const show = useCallback(
    (message: string, options: ToastOptions = {}) => {
      const id = nextId.current++;
      setToasts((t) => [...t.slice(-2), { id, message, ...options }]);
      window.setTimeout(() => dismiss(id), options.durationMs ?? (options.actionLabel ? 5000 : 3000));
    },
    [dismiss],
  );

  const value = useMemo(() => show, [show]);

  return (
    <ToastContext.Provider value={value}>
      {children}
      <div className="toast-region" role="status" aria-live="polite">
        {toasts.map((t) => {
          const Icon = icons[t.kind ?? 'success'];
          return (
            <div key={t.id} className={`toast toast--${t.kind ?? 'success'}`}>
              <Icon size={18} aria-hidden />
              <span className="toast__message">{t.message}</span>
              {t.actionLabel && (
                <button
                  type="button"
                  className="toast__action"
                  onClick={() => {
                    t.onAction?.();
                    dismiss(t.id);
                  }}
                >
                  {t.actionLabel}
                </button>
              )}
            </div>
          );
        })}
      </div>
    </ToastContext.Provider>
  );
}

export function useToast() {
  const ctx = useContext(ToastContext);
  if (!ctx) throw new Error('useToast must be used inside <ToastProvider>');
  return ctx;
}
