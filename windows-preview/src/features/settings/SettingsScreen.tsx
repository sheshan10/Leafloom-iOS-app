import { Bell, ChevronRight, Database, Info, LayoutGrid, List, Monitor, Moon, RotateCcw, Shield, Sparkles, Sun, Trash2 } from 'lucide-react';
import { useState, type ReactNode } from 'react';
import { useRouter } from '../../app/router';
import { ConfirmDialog } from '../../components/ConfirmDialog';
import { Segmented } from '../../components/FormFields';
import { PushedScreen } from '../../components/Layout';
import { useToast } from '../../components/Toast';
import { useData } from '../../data/store';
import type { CollectionLayout, ThemePreference } from '../../types/models';
import { clearSessionState } from '../../utils/sessionState';

export const APP_VERSION = '1.0.0 (preview)';

function Group({ title, footer, children }: { title: string; footer?: string; children: ReactNode }) {
  return (
    <section className="settings-group" aria-label={title}>
      <h2 className="settings-group__title">{title}</h2>
      <div className="settings-group__body">{children}</div>
      {footer && <p className="settings-group__footer">{footer}</p>}
    </section>
  );
}

function Row({ icon, label, value, onClick, danger }: { icon: ReactNode; label: string; value?: string; onClick?: () => void; danger?: boolean }) {
  const content = (
    <>
      <span className={`settings-row__icon ${danger ? 'is-danger' : ''}`} aria-hidden>
        {icon}
      </span>
      <span className={`settings-row__label ${danger ? 'is-danger' : ''}`}>{label}</span>
      {value && <span className="settings-row__value">{value}</span>}
      {onClick && !danger && <ChevronRight size={18} aria-hidden className="settings-row__chevron" />}
    </>
  );
  return onClick ? (
    <button type="button" className="settings-row" onClick={onClick}>
      {content}
    </button>
  ) : (
    <div className="settings-row">{content}</div>
  );
}

export function SettingsScreen() {
  const { preferences, actions } = useData();
  const router = useRouter();
  const toast = useToast();
  const [confirm, setConfirm] = useState<'reset' | 'erase' | null>(null);

  const run = async (kind: 'reset' | 'erase') => {
    setConfirm(null);
    try {
      if (kind === 'reset') await actions.resetToSampleData();
      else await actions.eraseAllData();
      clearSessionState();
      router.reset();
      toast(kind === 'reset' ? 'Sample data restored.' : 'All data erased.');
    } catch (e) {
      toast(e instanceof Error ? e.message : 'Could not reset data.', { kind: 'error' });
    }
  };

  const reminderValue = preferences.notificationPermission === 'denied' ? 'Not allowed' : preferences.remindersEnabled && preferences.notificationPermission === 'granted' ? `On · ${preferences.reminderHour}:00` : 'Off';

  return (
    <PushedScreen title="Settings">
      <Group title="Appearance" footer="Applies to the whole app.">
        <div className="settings-row settings-row--stacked">
          <Segmented<ThemePreference>
            label="Appearance"
            value={preferences.theme}
            onChange={(theme) => void actions.updatePreferences({ theme })}
            options={[
              { id: 'system', label: 'System', icon: <Monitor size={14} aria-hidden /> },
              { id: 'light', label: 'Light', icon: <Sun size={14} aria-hidden /> },
              { id: 'dark', label: 'Dark', icon: <Moon size={14} aria-hidden /> },
            ]}
          />
        </div>
        <div className="settings-row settings-row--stacked">
          <span className="settings-row__label">Collection layout</span>
          <Segmented<CollectionLayout>
            label="Collection layout"
            value={preferences.collectionLayout}
            onChange={(collectionLayout) => void actions.updatePreferences({ collectionLayout })}
            options={[
              { id: 'grid', label: 'Grid', icon: <LayoutGrid size={14} aria-hidden /> },
              { id: 'list', label: 'List', icon: <List size={14} aria-hidden /> },
            ]}
          />
        </div>
      </Group>

      <Group title="Reminders">
        <Row icon={<Bell size={18} />} label="Notifications & reminders" value={reminderValue} onClick={() => router.push({ name: 'reminderSettings' })} />
      </Group>

      <Group title="Help">
        <Row icon={<Sparkles size={18} />} label="Replay introduction" onClick={() => { router.reset(); void actions.updatePreferences({ onboardingComplete: false }); }} />
        <Row icon={<Info size={18} />} label="About LeafLoom" onClick={() => router.push({ name: 'about' })} />
      </Group>

      <Group title="Privacy" footer="LeafLoom is local-first. Plants, photos and notes are stored only on this device and are never uploaded. There are no accounts, analytics or advertising SDKs.">
        <Row icon={<Shield size={18} />} label="Data stored on this device only" />
      </Group>

      <Group title="Data" footer="Sample plants are labelled “Sample”. These actions cannot be undone.">
        <Row icon={<RotateCcw size={18} />} label="Reset to sample data" onClick={() => setConfirm('reset')} />
        <Row icon={<Trash2 size={18} />} label="Erase all data" danger onClick={() => setConfirm('erase')} />
      </Group>

      <Group title="About">
        <Row icon={<Database size={18} />} label="Version" value={APP_VERSION} />
      </Group>

      <ConfirmDialog
        open={confirm !== null}
        title={confirm === 'reset' ? 'Reset to sample data?' : 'Erase all data?'}
        message={confirm === 'reset' ? 'Your plants, care tasks, journal entries and identification history will be replaced by the sample collection.' : 'Every plant, care task, journal entry, photo and identification will be permanently deleted.'}
        confirmLabel={confirm === 'reset' ? 'Reset' : 'Erase everything'}
        onConfirm={() => confirm && void run(confirm)}
        onCancel={() => setConfirm(null)}
      />
    </PushedScreen>
  );
}
