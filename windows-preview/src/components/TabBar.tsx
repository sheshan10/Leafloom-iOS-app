import { BarChart3, CalendarCheck, Home, ScanLine, Sprout, type LucideIcon } from 'lucide-react';
import { tabTitles, useRouter, type Tab } from '../app/router';

const tabs: { id: Tab; icon: LucideIcon }[] = [
  { id: 'home', icon: Home },
  { id: 'plants', icon: Sprout },
  { id: 'identify', icon: ScanLine },
  { id: 'care', icon: CalendarCheck },
  { id: 'insights', icon: BarChart3 },
];

/** Custom tab bar with a raised central Identify action (mirrors native CustomTabBar). */
export function TabBar({ badges }: { badges?: Partial<Record<Tab, number>> }) {
  const { tab, selectTab } = useRouter();
  return (
    <nav className="tab-bar" aria-label="Main">
      {tabs.map(({ id, icon: Icon }) => {
        const selected = tab === id;
        const badge = badges?.[id];
        const label = tabTitles[id];
        return (
          <button
            key={id}
            type="button"
            className={`tab-bar__item ${id === 'identify' ? 'tab-bar__item--center' : ''} ${selected ? 'is-selected' : ''}`}
            aria-current={selected ? 'page' : undefined}
            aria-label={badge ? `${label}, ${badge} need attention` : label}
            onClick={() => selectTab(id)}
          >
            <span className="tab-bar__icon">
              <Icon size={id === 'identify' ? 26 : 22} aria-hidden strokeWidth={selected ? 2.4 : 1.9} />
              {badge ? <span className="tab-bar__badge">{badge > 9 ? '9+' : badge}</span> : null}
            </span>
            <span className="tab-bar__label">{label}</span>
          </button>
        );
      })}
    </nav>
  );
}
