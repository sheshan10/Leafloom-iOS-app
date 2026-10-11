import type { ReactNode } from 'react';
import { Search, X } from 'lucide-react';

export function SearchBar({ value, onChange, placeholder = 'Search' }: { value: string; onChange(v: string): void; placeholder?: string }) {
  return (
    <div className="search-bar" role="search">
      <Search size={18} aria-hidden className="search-bar__icon" />
      <input
        type="search"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        aria-label={placeholder}
        className="search-bar__input"
        enterKeyHint="search"
      />
      {value && (
        <button type="button" className="search-bar__clear" aria-label="Clear search" onClick={() => onChange('')}>
          <X size={16} aria-hidden />
        </button>
      )}
    </div>
  );
}

export function FilterChip({ label, selected, onToggle, icon }: { label: string; selected: boolean; onToggle(): void; icon?: ReactNode }) {
  return (
    <button type="button" className={`chip ${selected ? 'chip--selected' : ''}`} aria-pressed={selected} onClick={onToggle}>
      {icon}
      {label}
    </button>
  );
}
