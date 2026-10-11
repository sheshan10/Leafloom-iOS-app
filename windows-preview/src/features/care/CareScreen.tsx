import { BellOff, Plus } from 'lucide-react';
import { useMemo } from 'react';
import { useRouter } from '../../app/router';
import { IconButton, PrimaryButton } from '../../components/Button';
import { CareTaskRow } from '../../components/CareTaskRow';
import { Segmented } from '../../components/FormFields';
import { TabScreen } from '../../components/Layout';
import { EmptyState } from '../../components/States';
import { useData } from '../../data/store';
import { careStatus, filterTasks, type TaskFilter } from '../../utils/recurrence';
import { useSessionState } from '../../utils/sessionState';
import { useTaskCompletion } from './useTaskCompletion';

const emptyCopy: Record<TaskFilter, { title: string; message: string }> = {
  upcoming: { title: 'Nothing coming up', message: 'Add a care task, or set watering intervals on your plants to create a schedule.' },
  overdue: { title: 'Nothing overdue', message: 'Every task is on time. Nice work.' },
  completed: { title: 'No completed tasks yet', message: 'Tasks you complete will be kept here as history.' },
  all: { title: 'No care tasks', message: 'Create your first care task to get started.' },
};

export function CareScreen() {
  const { tasks, plants, preferences } = useData();
  const router = useRouter();
  const toggleTask = useTaskCompletion();
  const [filter, setFilter] = useSessionState<TaskFilter>('care.filter', 'upcoming');
  const plantById = useMemo(() => new Map(plants.map((p) => [p.id, p])), [plants]);
  const counts = useMemo(() => {
    const c = { upcoming: 0, overdue: 0, completed: 0 };
    tasks.forEach((t) => {
      const s = careStatus(t);
      if (s === 'completed') c.completed++;
      else if (s === 'overdue') c.overdue++;
      else c.upcoming++;
    });
    return c;
  }, [tasks]);
  const list = useMemo(() => filterTasks(tasks, filter), [tasks, filter]);
  const remindersOff = !preferences.remindersEnabled || preferences.notificationPermission !== 'granted';

  return (
    <TabScreen title="Care" subtitle={`${counts.upcoming + counts.overdue} open tasks`} trailing={<IconButton icon={Plus} label="Add care task" tone="filled" onClick={() => router.openSheet({ name: 'addTask' })} />}>
      <Segmented<TaskFilter>
        label="Filter tasks"
        value={filter}
        onChange={setFilter}
        options={[
          { id: 'upcoming', label: `Upcoming ${counts.upcoming}` },
          { id: 'overdue', label: `Overdue ${counts.overdue}` },
          { id: 'completed', label: `Done ${counts.completed}` },
        ]}
      />

      {remindersOff && (
        <button type="button" className="info-banner" onClick={() => router.push({ name: 'reminderSettings' })}>
          <BellOff size={18} aria-hidden />
          <span>Reminders are off. Tasks still work — tap to turn reminders on.</span>
        </button>
      )}

      {list.length === 0 ? (
        <EmptyState
          illustration="tasks"
          title={emptyCopy[filter].title}
          message={emptyCopy[filter].message}
          action={
            filter !== 'completed' && (
              <PrimaryButton icon={Plus} onClick={() => router.openSheet({ name: 'addTask' })}>
                Add care task
              </PrimaryButton>
            )
          }
        />
      ) : (
        <div className="list-card" aria-label={`${filter} tasks`}>
          {list.slice(0, filter === 'completed' ? 50 : undefined).map((t) => (
            <CareTaskRow key={t.id} task={t} plant={t.plantId ? plantById.get(t.plantId) : undefined} onOpen={() => router.push({ name: 'taskDetails', taskId: t.id })} onToggleComplete={() => void toggleTask(t)} />
          ))}
        </div>
      )}
    </TabScreen>
  );
}
