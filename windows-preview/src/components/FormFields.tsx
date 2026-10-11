import { AlertCircle } from 'lucide-react';
import { useId, type ReactNode } from 'react';

interface FieldShellProps {
  label: string;
  error?: string;
  hint?: string;
  required?: boolean;
  children: (ids: { inputId: string; describedBy?: string; invalid: boolean }) => ReactNode;
}

function FieldShell({ label, error, hint, required, children }: FieldShellProps) {
  const inputId = useId();
  const hintId = useId();
  const errorId = useId();
  const describedBy = [hint ? hintId : '', error ? errorId : ''].filter(Boolean).join(' ') || undefined;
  return (
    <div className={`field ${error ? 'field--invalid' : ''}`}>
      <label htmlFor={inputId} className="field__label">
        {label}
        {required && (
          <span className="field__required" aria-hidden>
            {' '}
            *
          </span>
        )}
      </label>
      {children({ inputId, describedBy, invalid: !!error })}
      {hint && !error && (
        <p id={hintId} className="field__hint">
          {hint}
        </p>
      )}
      {error && (
        <p id={errorId} className="field__error" role="alert">
          <AlertCircle size={14} aria-hidden /> {error}
        </p>
      )}
    </div>
  );
}

interface TextFieldProps {
  label: string;
  value: string;
  onChange(v: string): void;
  error?: string;
  hint?: string;
  required?: boolean;
  placeholder?: string;
  maxLength?: number;
  autoFocus?: boolean;
  type?: 'text' | 'date';
  max?: string;
}

export function TextField({ label, value, onChange, error, hint, required, placeholder, maxLength, autoFocus, type = 'text', max }: TextFieldProps) {
  return (
    <FieldShell label={label} error={error} hint={hint} required={required}>
      {({ inputId, describedBy, invalid }) => (
        <input
          id={inputId}
          type={type}
          className="field__input"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder={placeholder}
          maxLength={maxLength}
          aria-invalid={invalid || undefined}
          aria-required={required || undefined}
          aria-describedby={describedBy}
          data-autofocus={autoFocus || undefined}
          max={max}
        />
      )}
    </FieldShell>
  );
}

export function TextAreaField({ label, value, onChange, error, hint, placeholder, maxLength, rows = 4 }: Omit<TextFieldProps, 'type'> & { rows?: number }) {
  return (
    <FieldShell label={label} error={error} hint={hint}>
      {({ inputId, describedBy, invalid }) => (
        <textarea
          id={inputId}
          className="field__input field__textarea"
          value={value}
          rows={rows}
          onChange={(e) => onChange(e.target.value)}
          placeholder={placeholder}
          maxLength={maxLength}
          aria-invalid={invalid || undefined}
          aria-describedby={describedBy}
        />
      )}
    </FieldShell>
  );
}

export function NumberField({ label, value, onChange, error, hint, suffix, placeholder }: { label: string; value?: number; onChange(v?: number): void; error?: string; hint?: string; suffix?: string; placeholder?: string }) {
  return (
    <FieldShell label={label} error={error} hint={hint}>
      {({ inputId, describedBy, invalid }) => (
        <div className="field__affix">
          <input
            id={inputId}
            type="number"
            inputMode="numeric"
            className="field__input"
            value={value ?? ''}
            placeholder={placeholder}
            onChange={(e) => onChange(e.target.value === '' ? undefined : Number(e.target.value))}
            aria-invalid={invalid || undefined}
            aria-describedby={describedBy}
          />
          {suffix && <span className="field__suffix">{suffix}</span>}
        </div>
      )}
    </FieldShell>
  );
}

export function SelectField<T extends string>({ label, value, onChange, options, error, hint, required, placeholder }: { label: string; value?: T; onChange(v: T | undefined): void; options: { id: T; label: string }[]; error?: string; hint?: string; required?: boolean; placeholder?: string }) {
  return (
    <FieldShell label={label} error={error} hint={hint} required={required}>
      {({ inputId, describedBy, invalid }) => (
        <select
          id={inputId}
          className="field__input field__select"
          value={value ?? ''}
          onChange={(e) => onChange((e.target.value || undefined) as T | undefined)}
          aria-invalid={invalid || undefined}
          aria-describedby={describedBy}
          aria-required={required || undefined}
        >
          <option value="">{placeholder ?? 'Not set'}</option>
          {options.map((o) => (
            <option key={o.id} value={o.id}>
              {o.label}
            </option>
          ))}
        </select>
      )}
    </FieldShell>
  );
}

export function Toggle({ label, checked, onChange, description }: { label: string; checked: boolean; onChange(v: boolean): void; description?: string }) {
  const id = useId();
  const descId = useId();
  return (
    <div className="toggle-row">
      <div className="toggle-row__text">
        <label htmlFor={id} className="toggle-row__label">
          {label}
        </label>
        {description && (
          <p id={descId} className="t-footnote t-secondary">
            {description}
          </p>
        )}
      </div>
      <button
        id={id}
        type="button"
        role="switch"
        aria-checked={checked}
        aria-describedby={description ? descId : undefined}
        className={`switch ${checked ? 'is-on' : ''}`}
        onClick={() => onChange(!checked)}
      >
        <span className="switch__thumb" />
      </button>
    </div>
  );
}

export function Segmented<T extends string>({ label, value, options, onChange }: { label: string; value: T; options: { id: T; label: string; icon?: ReactNode }[]; onChange(v: T): void }) {
  return (
    <div className="segmented" role="radiogroup" aria-label={label}>
      {options.map((o) => (
        <button
          key={o.id}
          type="button"
          role="radio"
          aria-checked={value === o.id}
          className={`segmented__item ${value === o.id ? 'is-selected' : ''}`}
          onClick={() => onChange(o.id)}
        >
          {o.icon}
          <span>{o.label}</span>
        </button>
      ))}
    </div>
  );
}

export function FormSection({ title, children, footer }: { title?: string; children: ReactNode; footer?: string }) {
  return (
    <fieldset className="form-section">
      {title && <legend className="form-section__title">{title}</legend>}
      <div className="form-section__body">{children}</div>
      {footer && <p className="form-section__footer">{footer}</p>}
    </fieldset>
  );
}
