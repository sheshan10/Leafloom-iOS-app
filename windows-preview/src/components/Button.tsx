import type { ButtonHTMLAttributes, ReactNode } from 'react';
import type { LucideIcon } from 'lucide-react';

type Variant = 'primary' | 'secondary' | 'ghost' | 'danger';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  icon?: LucideIcon;
  fullWidth?: boolean;
  size?: 'md' | 'sm';
  busy?: boolean;
  children: ReactNode;
}

function BaseButton({ variant, icon: Icon, fullWidth, size = 'md', busy, children, className = '', ...rest }: ButtonProps & { variant: Variant }) {
  return (
    <button
      type="button"
      {...rest}
      aria-busy={busy || undefined}
      disabled={rest.disabled || busy}
      className={`btn btn--${variant} btn--${size} ${fullWidth ? 'btn--full' : ''} ${className}`}
    >
      {busy ? <span className="btn__spinner" aria-hidden /> : Icon && <Icon size={size === 'sm' ? 16 : 18} aria-hidden />}
      <span>{children}</span>
    </button>
  );
}

export const PrimaryButton = (p: ButtonProps) => <BaseButton variant="primary" {...p} />;
export const SecondaryButton = (p: ButtonProps) => <BaseButton variant="secondary" {...p} />;
export const GhostButton = (p: ButtonProps) => <BaseButton variant="ghost" {...p} />;
export const DangerButton = (p: ButtonProps) => <BaseButton variant="danger" {...p} />;

interface IconButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  icon: LucideIcon;
  label: string;
  tone?: 'plain' | 'filled' | 'onImage';
  pressed?: boolean;
  iconClassName?: string;
}

/** 44×44 hit target regardless of icon size, labelled for screen readers. */
export function IconButton({ icon: Icon, label, tone = 'plain', pressed, iconClassName, className = '', ...rest }: IconButtonProps) {
  return (
    <button
      type="button"
      aria-label={label}
      title={label}
      aria-pressed={pressed}
      {...rest}
      className={`icon-btn icon-btn--${tone} ${className}`}
    >
      <Icon size={20} aria-hidden className={iconClassName} />
    </button>
  );
}
