import {
  BarChart3,
  CalendarCheck,
  ChevronDown,
  Database,
  Glasses,
  Home,
  Monitor,
  Moon,
  Plus,
  RotateCcw,
  ScanLine,
  Settings,
  Smartphone,
  Sprout,
  Sun,
  Trash2,
} from 'lucide-react';
import { useState } from 'react';
import { ConfirmDialog } from '../components/ConfirmDialog';
import { Segmented, Toggle } from '../components/FormFields';
import { BrandMark } from '../components/Icons';
import { useData } from '../data/store';
import type { ThemePreference } from '../types/models';
import { devices, type DeviceId } from './devices';
import type { PreviewMode } from './PreviewShell';
import { useRouter, type Tab } from './router';
import { describeScreen } from './screenInfo';

interface Props {
  deviceId: DeviceId;
  onDeviceChange(id: DeviceId): void;
  mode: PreviewMode;
  onModeChange(m: PreviewMode): void;
  typeScale: number;
  onTypeScaleChange(v: number): void;
  reducedMotion: boolean;
  onReducedMotionChange(v: boolean): void;
  collapsible: boolean;
}

const shortcuts: { tab: Tab; label: string; icon: typeof Home }[] = [
  { tab: 'home', label: 'Home', icon: Home },
  { tab: 'plants', label: 'My Plants', icon: Sprout },
  { tab: 'identify', label: 'Identify', icon: ScanLine },
  { tab: 'care', label: 'Care', icon: CalendarCheck },
  { tab: 'insights', label: 'Insights', icon: BarChart3 },
];

const typeSizes = [
  { value: 0.88, label: 'Small' },
  { value: 1, label: 'Default' },
  { value: 1.18, label: 'Large' },
  { value: 1.35, label: 'XL (accessibility)' },
];

/** Development-only controls. This panel exists only in the browser preview, never in the native app. */
export function DevPanel(p: Props) {
  const data = useData();
  const router = useRouter();
  const [open, setOpen] = useState(!p.collapsible);
  const [confirm, setConfirm] = useState<'reset' | 'erase' | null>(null);
  const [status, setStatus] = useState('');
  const info = describeScreen(data.preferences, router.tab, router.current, router.sheet);
  const onboarding = !data.preferences.onboardingComplete;

  const go = (tab: Tab) => {
    p.onModeChange('iphone');
    router.closeSheet();
    router.selectTab(tab);
  };

  const runData = async (kind: 'reset' | 'erase') => {
    setConfirm(null);
    try {
      if (kind === 'reset') await data.actions.resetToSampleData();
      else await data.actions.eraseAllData();
      router.reset();
      setStatus(kind === 'reset' ? 'Sample data restored.' : 'All preview data erased.');
    } catch (e) {
      setStatus(e instanceof Error ? e.message : 'Could not update data.');
    }
  };

  return (
    <aside className={`dev-panel ${open ? 'is-open' : ''}`} aria-label="Preview tools">
      <header className="dev-panel__header">
        <BrandMark size={36} />
        <div>
          <p className="dev-panel__title">LeafLoom</p>
          <p className="dev-panel__subtitle">Windows browser preview</p>
        </div>
        {p.collapsible && (
          <button type="button" className="dev-panel__toggle" aria-expanded={open} onClick={() => setOpen((o) => !o)}>
            Tools <ChevronDown size={16} aria-hidden className={open ? 'is-flipped' : ''} />
          </button>
        )}
      </header>

      {open && (
        <div className="dev-panel__body">
          <p className="dev-panel__note">
            A development companion that mirrors the native SwiftUI app’s design and workflows. Data lives in this browser’s IndexedDB only. Machine-learning results and notifications here are <strong>simulated</strong>.
          </p>

          <section className="dev-card" aria-labelledby="dev-screen">
            <p className="dev-card__eyebrow" id="dev-screen">
              Current screen
            </p>
            <p className="dev-card__screen" data-testid="current-screen">
              {p.mode === 'vision' ? 'LeafLoom Spatial (visionOS, Part B)' : info.name}
            </p>
            <p className="dev-card__desc">
              {p.mode === 'vision'
                ? '2D simulation of the visionOS prototype: a window, a volumetric plant shelf and an immersive room arrangement. Real implementation in partB-visionos/.'
                : info.description}
            </p>
            {p.mode === 'iphone' && <code className="dev-card__code">native-ios/LeafLoom/{info.native}</code>}
          </section>

          <section className="dev-card" aria-labelledby="dev-nav">
            <p className="dev-card__eyebrow" id="dev-nav">
              Navigate
            </p>
            <div className="dev-grid">
              {shortcuts.map(({ tab, label, icon: Icon }) => (
                <button key={tab} type="button" className="dev-btn" onClick={() => go(tab)} disabled={onboarding}>
                  <Icon size={15} aria-hidden /> {label}
                </button>
              ))}
              <button type="button" className="dev-btn" disabled={onboarding} onClick={() => { p.onModeChange('iphone'); router.closeSheet(); router.push({ name: 'settings' }, 'home'); }}>
                <Settings size={15} aria-hidden /> Settings
              </button>
              <button type="button" className="dev-btn" disabled={onboarding} onClick={() => { p.onModeChange('iphone'); router.openSheet({ name: 'addPlant' }); }}>
                <Plus size={15} aria-hidden /> Add plant
              </button>
              <button type="button" className="dev-btn" onClick={() => { p.onModeChange('iphone'); router.reset(); void data.actions.updatePreferences({ onboardingComplete: false }); }}>
                <RotateCcw size={15} aria-hidden /> Onboarding
              </button>
            </div>
          </section>

          <section className="dev-card" aria-labelledby="dev-look">
            <p className="dev-card__eyebrow" id="dev-look">
              Appearance
            </p>
            <Segmented<ThemePreference>
              label="Theme"
              value={data.preferences.theme}
              onChange={(theme) => void data.actions.updatePreferences({ theme })}
              options={[
                { id: 'system', label: 'System', icon: <Monitor size={14} aria-hidden /> },
                { id: 'light', label: 'Light', icon: <Sun size={14} aria-hidden /> },
                { id: 'dark', label: 'Dark', icon: <Moon size={14} aria-hidden /> },
              ]}
            />
            <label className="dev-label" htmlFor="dev-type">
              Text size (simulated Dynamic Type)
            </label>
            <select id="dev-type" className="dev-select" value={p.typeScale} onChange={(e) => p.onTypeScaleChange(Number(e.target.value))}>
              {typeSizes.map((t) => (
                <option key={t.value} value={t.value}>
                  {t.label}
                </option>
              ))}
            </select>
            <Toggle label="Reduce motion" checked={p.reducedMotion} onChange={p.onReducedMotionChange} />
          </section>

          <section className="dev-card" aria-labelledby="dev-device">
            <p className="dev-card__eyebrow" id="dev-device">
              Device
            </p>
            <Segmented<PreviewMode>
              label="Platform"
              value={p.mode}
              onChange={p.onModeChange}
              options={[
                { id: 'iphone', label: 'iPhone app', icon: <Smartphone size={14} aria-hidden /> },
                { id: 'vision', label: 'visionOS (Part B)', icon: <Glasses size={14} aria-hidden /> },
              ]}
            />
            {p.mode === 'iphone' && (
              <select aria-label="Device size" className="dev-select" value={p.deviceId} onChange={(e) => p.onDeviceChange(e.target.value as DeviceId)}>
                {Object.values(devices).map((d) => (
                  <option key={d.id} value={d.id}>
                    {d.label}
                  </option>
                ))}
              </select>
            )}
          </section>

          <section className="dev-card" aria-labelledby="dev-data">
            <p className="dev-card__eyebrow" id="dev-data">
              <Database size={13} aria-hidden /> Preview data
            </p>
            <p className="dev-card__desc">
              {data.plants.length} plants · {data.tasks.length} care tasks · {data.journal.length} journal entries
            </p>
            <div className="dev-grid">
              <button type="button" className="dev-btn" onClick={() => setConfirm('reset')}>
                <RotateCcw size={15} aria-hidden /> Reset sample data
              </button>
              <button type="button" className="dev-btn dev-btn--danger" onClick={() => setConfirm('erase')}>
                <Trash2 size={15} aria-hidden /> Erase all
              </button>
            </div>
            {status && (
              <p className="dev-card__status" role="status">
                {status}
              </p>
            )}
          </section>
        </div>
      )}

      <div className="dev-dialog-host">
        <ConfirmDialog
          open={confirm !== null}
          title={confirm === 'reset' ? 'Reset to sample data?' : 'Erase all preview data?'}
          message={confirm === 'reset' ? 'All plants, tasks and journal entries in this browser will be replaced with the sample collection.' : 'Every plant, task, journal entry and identification in this browser will be permanently removed.'}
          confirmLabel={confirm === 'reset' ? 'Reset' : 'Erase all'}
          onConfirm={() => confirm && void runData(confirm)}
          onCancel={() => setConfirm(null)}
        />
      </div>
    </aside>
  );
}
