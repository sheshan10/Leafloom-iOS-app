import { useEffect, useMemo, useRef } from 'react';
import { ErrorState, LoadingView } from '../components/States';
import { TabBar } from '../components/TabBar';
import { useToast } from '../components/Toast';
import { useData } from '../data/store';
import { CareScreen } from '../features/care/CareScreen';
import { TaskDetailsScreen } from '../features/care/TaskDetailsScreen';
import { TaskFormSheet } from '../features/care/TaskFormSheet';
import { CollectionScreen } from '../features/collection/CollectionScreen';
import { HomeScreen } from '../features/dashboard/HomeScreen';
import { IdentifyFlowProvider } from '../features/identify/IdentifyFlow';
import { IdentifyResultScreen } from '../features/identify/IdentifyResultScreen';
import { IdentifyScreen } from '../features/identify/IdentifyScreen';
import { InsightsScreen } from '../features/insights/InsightsScreen';
import { JournalFormSheet } from '../features/journal/JournalFormSheet';
import { JournalScreen } from '../features/journal/JournalScreen';
import { Onboarding } from '../features/onboarding/Onboarding';
import { PlantDetailsScreen } from '../features/plants/PlantDetailsScreen';
import { PlantFormSheet } from '../features/plants/PlantFormSheet';
import { AboutScreen } from '../features/settings/AboutScreen';
import { ReminderSettingsScreen } from '../features/settings/ReminderSettingsScreen';
import { SettingsScreen } from '../features/settings/SettingsScreen';
import { careStatus } from '../utils/recurrence';
import { useRouter, type Route, type Tab } from './router';

function RouteView({ route }: { route: Route }) {
  switch (route.name) {
    case 'plantDetails':
      return <PlantDetailsScreen plantId={route.plantId} />;
    case 'taskDetails':
      return <TaskDetailsScreen taskId={route.taskId} />;
    case 'journal':
      return <JournalScreen plantId={route.plantId} />;
    case 'identifyResult':
      return <IdentifyResultScreen />;
    case 'settings':
      return <SettingsScreen />;
    case 'reminderSettings':
      return <ReminderSettingsScreen />;
    case 'about':
      return <AboutScreen />;
  }
}

function TabRoot({ tab }: { tab: Tab }) {
  switch (tab) {
    case 'home':
      return <HomeScreen />;
    case 'plants':
      return <CollectionScreen />;
    case 'identify':
      return <IdentifyScreen />;
    case 'care':
      return <CareScreen />;
    case 'insights':
      return <InsightsScreen />;
  }
}

function SheetHost() {
  const { sheet } = useRouter();
  if (!sheet) return null;
  switch (sheet.name) {
    case 'addPlant':
      return <PlantFormSheet prefill={sheet.prefill} identificationId={sheet.identificationId} />;
    case 'editPlant':
      return <PlantFormSheet plantId={sheet.plantId} />;
    case 'addTask':
      return <TaskFormSheet plantId={sheet.plantId} />;
    case 'editTask':
      return <TaskFormSheet taskId={sheet.taskId} />;
    case 'addJournal':
      return <JournalFormSheet plantId={sheet.plantId} />;
    case 'editJournal':
      return <JournalFormSheet entryId={sheet.entryId} />;
  }
}

/** Shows one in-app "reminder" per session. Clearly labelled: the browser does not reproduce iOS notifications. */
function ReminderSimulator() {
  const { tasks, preferences, status } = useData();
  const { selectTab } = useRouter();
  const toast = useToast();
  const shown = useRef(false);
  useEffect(() => {
    if (shown.current || status !== 'ready' || !preferences.onboardingComplete) return;
    if (!preferences.remindersEnabled || preferences.notificationPermission !== 'granted') return;
    const due = tasks.filter((t) => ['dueToday', 'overdue'].includes(careStatus(t)));
    if (due.length === 0) return;
    shown.current = true;
    const id = window.setTimeout(
      () =>
        toast(`Simulated reminder: ${due.length} care task${due.length === 1 ? '' : 's'} need attention today.`, {
          kind: 'reminder',
          actionLabel: 'View',
          onAction: () => selectTab('care'),
          durationMs: 6000,
        }),
      1200,
    );
    return () => window.clearTimeout(id);
  }, [tasks, preferences, status, toast, selectTab]);
  return null;
}

export function PhoneApp() {
  const data = useData();
  const router = useRouter();

  const careBadge = useMemo(
    () => data.tasks.filter((t) => ['dueToday', 'overdue'].includes(careStatus(t))).length,
    [data.tasks],
  );

  if (data.status === 'loading') {
    return (
      <div className="app-root app-root--center">
        <LoadingView label="Loading your garden…" />
      </div>
    );
  }
  if (data.status === 'error') {
    return (
      <div className="app-root app-root--center">
        <ErrorState title="Your garden couldn’t be loaded" message={data.loadError ?? 'Storage is unavailable in this browser.'} onRetry={() => void data.reload()} />
      </div>
    );
  }
  if (!data.preferences.onboardingComplete) {
    return (
      <div className="app-root">
        <Onboarding />
      </div>
    );
  }

  const current = router.current;
  const screenKey = current ? `${router.tab}-${router.stack.length}-${JSON.stringify(current)}` : `${router.tab}-root`;

  return (
    <IdentifyFlowProvider>
      <div className="app-root">
        <div key={screenKey} className={`screen-host ${current ? 'screen-host--push' : 'screen-host--tab'}`}>
          {current ? <RouteView route={current} /> : <TabRoot tab={router.tab} />}
        </div>
        <TabBar badges={{ care: careBadge }} />
        <SheetHost />
        <ReminderSimulator />
      </div>
    </IdentifyFlowProvider>
  );
}
