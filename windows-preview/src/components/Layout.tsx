import { ChevronLeft } from 'lucide-react';
import { useEffect, useRef, type ReactNode } from 'react';
import { useRouter } from '../app/router';

/** Section title with an optional trailing action, like a SwiftUI Section header. */
export function SectionHeader({ title, action, id }: { title: string; action?: ReactNode; id?: string }) {
  return (
    <div className="section-header">
      <h2 className="t-title3" id={id}>
        {title}
      </h2>
      {action}
    </div>
  );
}

/** Root tab screen: large editorial title that scrolls with content. */
export function TabScreen({ title, subtitle, trailing, children, label }: { title: string; subtitle?: ReactNode; trailing?: ReactNode; children: ReactNode; label?: string }) {
  const { navKey } = useRouter();
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    ref.current?.scrollTo?.({ top: 0 });
  }, [navKey]);
  return (
    <div className="screen screen--tab" ref={ref} aria-label={label ?? title}>
      <header className="large-header">
        <div className="large-header__text">
          {subtitle && <p className="t-eyebrow">{subtitle}</p>}
          <h1 className="t-large-title">{title}</h1>
        </div>
        {trailing && <div className="large-header__actions">{trailing}</div>}
      </header>
      <div className="screen__content">{children}</div>
    </div>
  );
}

/** Pushed screen with a back button and compact title, like a NavigationStack destination. */
export function PushedScreen({ title, trailing, children, hero, backLabel = 'Back' }: { title: string; trailing?: ReactNode; children: ReactNode; hero?: ReactNode; backLabel?: string }) {
  const { pop, navKey } = useRouter();
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    ref.current?.scrollTo?.({ top: 0 });
  }, [navKey]);
  return (
    <div className="screen screen--pushed" ref={ref}>
      <nav className={`nav-bar ${hero ? 'nav-bar--over-hero' : ''}`} aria-label="Navigation">
        <button type="button" className="nav-bar__back" onClick={pop}>
          <ChevronLeft size={22} aria-hidden />
          <span>{backLabel}</span>
        </button>
        <h1 className="nav-bar__title">{hero ? '' : title}</h1>
        <div className="nav-bar__trailing">{trailing}</div>
      </nav>
      {hero}
      <div className="screen__content">{children}</div>
    </div>
  );
}

export function Card({ children, className = '', as: Tag = 'section', ...rest }: { children: ReactNode; className?: string; as?: 'section' | 'div' | 'article'; 'aria-labelledby'?: string }) {
  return (
    <Tag className={`card ${className}`} {...rest}>
      {children}
    </Tag>
  );
}
