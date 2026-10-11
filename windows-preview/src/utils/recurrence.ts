import type { CareTask } from '../types/models';
import { addDays, calendarDaysBetween, startOfDay } from './dates';

export type CareStatus = 'completed' | 'overdue' | 'dueToday' | 'upcoming';

export const careStatus = (task: CareTask, now = new Date()): CareStatus => {
  if (task.isCompleted) return 'completed';
  const diff = calendarDaysBetween(now, new Date(task.dueDate));
  if (diff < 0) return 'overdue';
  if (diff === 0) return 'dueToday';
  return 'upcoming';
};

/**
 * Next occurrence = start of the completion day + interval, at the original due time-of-day.
 * Basing it on the completion day (not the old due date) avoids a backlog of overdue
 * occurrences when a task is completed late.
 */
export const nextDueDate = (task: CareTask, completedAt: Date): Date | undefined => {
  const interval = task.recurrenceIntervalDays;
  if (!interval || interval < 1) return undefined;
  const due = new Date(task.dueDate);
  const next = addDays(startOfDay(completedAt), interval);
  next.setHours(due.getHours(), due.getMinutes(), 0, 0);
  return next;
};

export interface CompletionResult {
  completed: CareTask;
  spawned?: CareTask;
}

export const completeTask = (task: CareTask, now: Date, newId: () => string): CompletionResult => {
  if (task.isCompleted) return { completed: task };
  const stamp = now.toISOString();
  const nextDue = nextDueDate(task, now);
  const spawned: CareTask | undefined = nextDue
    ? {
        ...task,
        id: newId(),
        dueDate: nextDue.toISOString(),
        isCompleted: false,
        completedAt: undefined,
        spawnedTaskId: undefined,
        notes: undefined,
        createdAt: stamp,
        updatedAt: stamp,
      }
    : undefined;
  return {
    completed: { ...task, isCompleted: true, completedAt: stamp, spawnedTaskId: spawned?.id, updatedAt: stamp },
    spawned,
  };
};

export interface UndoResult {
  restored: CareTask;
  /** Id of the spawned occurrence to delete, if it is still untouched. */
  deleteTaskId?: string;
}

export const undoCompletion = (task: CareTask, spawned: CareTask | undefined, now: Date): UndoResult => {
  const untouched = spawned && !spawned.isCompleted && spawned.createdAt === spawned.updatedAt;
  return {
    restored: {
      ...task,
      isCompleted: false,
      completedAt: undefined,
      spawnedTaskId: undefined,
      updatedAt: now.toISOString(),
    },
    deleteTaskId: untouched ? spawned.id : undefined,
  };
};

export const sortByDueDate = (a: CareTask, b: CareTask) =>
  new Date(a.dueDate).getTime() - new Date(b.dueDate).getTime();

export type TaskFilter = 'upcoming' | 'overdue' | 'completed' | 'all';

export const filterTasks = (tasks: CareTask[], filter: TaskFilter, now = new Date()) => {
  const list = tasks.filter((t) => {
    const s = careStatus(t, now);
    switch (filter) {
      case 'upcoming':
        return s === 'upcoming' || s === 'dueToday';
      case 'overdue':
        return s === 'overdue';
      case 'completed':
        return s === 'completed';
      default:
        return true;
    }
  });
  if (filter === 'completed') {
    return list.sort((a, b) => new Date(b.completedAt ?? 0).getTime() - new Date(a.completedAt ?? 0).getTime());
  }
  return list.sort(sortByDueDate);
};
