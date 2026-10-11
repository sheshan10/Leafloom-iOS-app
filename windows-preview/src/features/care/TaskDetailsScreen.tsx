import { CalendarDays, Check, ChevronRight, Pencil, Repeat, RotateCcw, Trash2 } from 'lucide-react';
import { useMemo, useState } from 'react';
import { useRouter } from '../../app/router';
import { DangerButton, IconButton, PrimaryButton, SecondaryButton } from '../../components/Button';
import { ConfirmDialog } from '../../components/ConfirmDialog';
import { CareIcon } from '../../components/Icons';
import { Card, PushedScreen, SectionHeader } from '../../components/Layout';
import { PlantThumbnail } from '../../components/PlantThumbnail';
import { StatusBadge } from '../../components/StatusBadge';
import { ErrorState } from '../../components/States';
import { useToast } from '../../components/Toast';
import { careCategoryLabel } from '../../data/catalog';
import { useData } from '../../data/store';
import { formatDate, relativeDay } from '../../utils/dates';
import { careStatus } from '../../utils/recurrence';
import { useTaskCompletion } from './useTaskCompletion';

export function TaskDetailsScreen({ taskId }: { taskId: string }) {
  const { tasks, plants, actions } = useData();
  const router = useRouter();
  const toast = useToast();
  const toggleTask = useTaskCompletion();
  const [confirm, setConfirm] = useState(false);
  const task = tasks.find((t) => t.id === taskId);
  const plant = task?.plantId ? plants.find((p) => p.id === task.plantId) : undefined;
  const series = useMemo(
    () => (task ? tasks.filter((t) => t.seriesId === task.seriesId && t.isCompleted).sort((a, b) => (b.completedAt ?? '').localeCompare(a.completedAt ?? '')) : []),
    [tasks, task],
  );

  if (!task) {
    return (
      <PushedScreen title="Task">
        <ErrorState title="Task not found" message="This care task may have been deleted." />
      </PushedScreen>
    );
  }

  const status = careStatus(task);
  const onDelete = async () => {
    setConfirm(false);
    router.pop();
    try {
      await actions.deleteTask(task.id);
      toast('Care task deleted.');
    } catch (e) {
      toast(e instanceof Error ? e.message : 'Could not delete the task.', { kind: 'error' });
    }
  };

  return (
    <PushedScreen title="Care task" trailing={<IconButton icon={Pencil} label="Edit task" onClick={() => router.openSheet({ name: 'editTask', taskId: task.id })} />}>
      <div className="task-hero">
        <CareIcon category={task.category} size={26} />
        <div>
          <p className="t-eyebrow">{careCategoryLabel(task.category)}</p>
          <h1 className="t-title">{task.title}</h1>
        </div>
      </div>
      <div className="badge-row">
        <StatusBadge status={status} />
      </div>

      <Card className="fact-list">
        <div className="fact-list__row">
          <CalendarDays size={18} aria-hidden />
          <span>Due</span>
          <strong>
            {formatDate(task.dueDate, { weekday: 'short', day: 'numeric', month: 'short' })} · {relativeDay(task.dueDate)}
          </strong>
        </div>
        <div className="fact-list__row">
          <Repeat size={18} aria-hidden />
          <span>Repeats</span>
          <strong>{task.recurrenceIntervalDays ? `Every ${task.recurrenceIntervalDays} days` : 'Does not repeat'}</strong>
        </div>
        {task.completedAt && (
          <div className="fact-list__row">
            <Check size={18} aria-hidden />
            <span>Completed</span>
            <strong>{formatDate(task.completedAt, { weekday: 'short', day: 'numeric', month: 'short' })}</strong>
          </div>
        )}
      </Card>

      {plant && (
        <button type="button" className="linked-plant" onClick={() => router.push({ name: 'plantDetails', plantId: plant.id })}>
          <PlantThumbnail plant={plant} className="linked-plant__image" />
          <span className="linked-plant__text">
            <span className="t-headline">{plant.name}</span>
            <span className="t-footnote t-secondary">{plant.commonName ?? 'View plant'}</span>
          </span>
          <ChevronRight size={18} aria-hidden />
        </button>
      )}

      {(task.descriptionText || task.notes) && (
        <Card>
          {task.descriptionText && <p className="t-body">{task.descriptionText}</p>}
          {task.notes && <p className="t-subhead t-secondary notes-text">{task.notes}</p>}
        </Card>
      )}

      <div className="details-actions">
        {task.isCompleted ? (
          <SecondaryButton icon={RotateCcw} fullWidth onClick={() => void toggleTask(task)}>
            Mark as not done
          </SecondaryButton>
        ) : (
          <PrimaryButton icon={Check} fullWidth onClick={() => void toggleTask(task)}>
            Mark as done
          </PrimaryButton>
        )}
      </div>

      {task.recurrenceIntervalDays ? (
        <section aria-labelledby="series-history">
          <SectionHeader title="History" id="series-history" />
          {series.length === 0 ? (
            <p className="inline-empty">No completed occurrences yet.</p>
          ) : (
            <ul className="history-list">
              {series.slice(0, 12).map((t) => (
                <li key={t.id}>
                  <span>
                    <Check size={14} aria-hidden /> Completed
                  </span>
                  <span className="t-footnote t-secondary">{t.completedAt ? formatDate(t.completedAt, { weekday: 'short', day: 'numeric', month: 'short' }) : ''}</span>
                </li>
              ))}
            </ul>
          )}
        </section>
      ) : null}

      <div className="details-actions">
        <DangerButton icon={Trash2} fullWidth onClick={() => setConfirm(true)}>
          Delete task
        </DangerButton>
      </div>

      <ConfirmDialog
        open={confirm}
        title="Delete this care task?"
        message={task.recurrenceIntervalDays ? 'Only this occurrence is deleted. Completed history is kept.' : 'This task will be permanently removed.'}
        confirmLabel="Delete task"
        onConfirm={() => void onDelete()}
        onCancel={() => setConfirm(false)}
      />
    </PushedScreen>
  );
}
