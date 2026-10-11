import { useCallback } from 'react';
import { useToast } from '../../components/Toast';
import { useData } from '../../data/store';
import type { CareTask } from '../../types/models';
import { formatDate } from '../../utils/dates';

/** Shared complete / undo behaviour with feedback, used by every list that shows care tasks. */
export function useTaskCompletion() {
  const { actions } = useData();
  const toast = useToast();
  return useCallback(
    async (task: CareTask) => {
      try {
        if (task.isCompleted) {
          await actions.undoComplete(task.id);
          toast(`“${task.title}” marked as not done.`, { kind: 'info' });
          return;
        }
        const { spawned } = await actions.completeTask(task.id);
        toast(spawned ? `Done! Next one scheduled for ${formatDate(spawned.dueDate, { weekday: 'short', day: 'numeric', month: 'short' })}.` : `“${task.title}” completed.`, {
          kind: 'success',
          actionLabel: 'Undo',
          onAction: () => void actions.undoComplete(task.id),
        });
      } catch (e) {
        toast(e instanceof Error ? e.message : 'Could not update the task.', { kind: 'error' });
      }
    },
    [actions, toast],
  );
}
