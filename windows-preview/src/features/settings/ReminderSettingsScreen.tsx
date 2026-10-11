import { BellOff, BellRing, Info } from 'lucide-react';
import { useState } from 'react';
import { SecondaryButton } from '../../components/Button';
import { Toggle } from '../../components/FormFields';
import { Card, PushedScreen } from '../../components/Layout';
import { useData } from '../../data/store';
import { SimulatedPermissionPrompt } from './SimulatedPermissionPrompt';

export function ReminderSettingsScreen() {
  const { preferences, actions } = useData();
  const [prompt, setPrompt] = useState(false);
  const permission = preferences.notificationPermission;

  const onToggle = (on: boolean) => {
    if (on && permission === 'notDetermined') {
      setPrompt(true);
      return;
    }
    void actions.updatePreferences({ remindersEnabled: on });
  };

  return (
    <PushedScreen title="Reminders">
      <div className="demo-banner" role="note">
        <Info size={18} aria-hidden />
        <p>The browser preview only simulates reminders as in-app banners. The iPhone app schedules real local notifications with UserNotifications.</p>
      </div>

      {permission === 'denied' && (
        <Card className="permission-card">
          <BellOff size={22} aria-hidden />
          <div>
            <p className="t-headline">Notifications are not allowed</p>
            <p className="t-footnote t-secondary">LeafLoom still works fully. On iPhone, open Settings › LeafLoom › Notifications to allow reminders.</p>
            <SecondaryButton size="sm" onClick={() => void actions.updatePreferences({ notificationPermission: 'notDetermined' })}>
              Simulate allowing in Settings
            </SecondaryButton>
          </div>
        </Card>
      )}

      <Card>
        <Toggle label="Care reminders" description="A reminder on the day each care task is due." checked={preferences.remindersEnabled && permission === 'granted'} onChange={onToggle} />
        <div className="field">
          <label className="field__label" htmlFor="reminder-hour">
            Reminder time
          </label>
          <select
            id="reminder-hour"
            className="field__input field__select"
            value={preferences.reminderHour}
            disabled={!preferences.remindersEnabled || permission !== 'granted'}
            onChange={(e) => void actions.updatePreferences({ reminderHour: Number(e.target.value) })}
          >
            {Array.from({ length: 15 }, (_, i) => i + 6).map((h) => (
              <option key={h} value={h}>
                {`${h}:00`}
              </option>
            ))}
          </select>
          <p className="field__hint">New tasks default to this time. Native reminders are scheduled at this hour on the due date.</p>
        </div>
      </Card>

      {permission === 'granted' && preferences.remindersEnabled && (
        <p className="inline-success">
          <BellRing size={16} aria-hidden /> Reminders are on.
        </p>
      )}

      <SimulatedPermissionPrompt
        open={prompt}
        onResult={(granted) => {
          setPrompt(false);
          void actions.updatePreferences({ notificationPermission: granted ? 'granted' : 'denied', remindersEnabled: granted });
        }}
      />
    </PushedScreen>
  );
}
