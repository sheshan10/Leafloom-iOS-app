import { NOW, makeTask } from '../test/fixtures';
import { careStatus, completeTask, filterTasks, nextDueDate, undoCompletion } from './recurrence';

const at = (d: number, h = 9, m = 0) => new Date(2026, 9, d, h, m);

describe('careStatus', () => {
  it('classifies overdue, due today, upcoming and completed tasks', () => {
    expect(careStatus(makeTask({ dueDate: at(6).toISOString() }), NOW)).toBe('overdue');
    expect(careStatus(makeTask({ dueDate: at(7, 23).toISOString() }), NOW)).toBe('dueToday');
    expect(careStatus(makeTask({ dueDate: at(7, 6).toISOString() }), NOW)).toBe('dueToday');
    expect(careStatus(makeTask({ dueDate: at(8).toISOString() }), NOW)).toBe('upcoming');
    expect(careStatus(makeTask({ dueDate: at(1).toISOString(), isCompleted: true }), NOW)).toBe('completed');
  });
});

describe('nextDueDate', () => {
  it('returns undefined for non-recurring tasks', () => {
    expect(nextDueDate(makeTask(), NOW)).toBeUndefined();
    expect(nextDueDate(makeTask({ recurrenceIntervalDays: 0 }), NOW)).toBeUndefined();
  });

  it('is based on the completion day and keeps the original time of day', () => {
    const task = makeTask({ dueDate: at(1, 8, 30).toISOString(), recurrenceIntervalDays: 7 });
    const next = nextDueDate(task, at(7, 22))!;
    expect(next.getDate()).toBe(14);
    expect(next.getHours()).toBe(8);
    expect(next.getMinutes()).toBe(30);
  });

  it('handles month boundaries', () => {
    const task = makeTask({ dueDate: at(28).toISOString(), recurrenceIntervalDays: 5 });
    const next = nextDueDate(task, at(30))!;
    expect(next.getMonth()).toBe(10);
    expect(next.getDate()).toBe(4);
  });
});

describe('completeTask / undoCompletion', () => {
  it('completes a one-off task without spawning', () => {
    const { completed, spawned } = completeTask(makeTask(), NOW, () => 'new');
    expect(completed.isCompleted).toBe(true);
    expect(completed.completedAt).toBe(NOW.toISOString());
    expect(spawned).toBeUndefined();
  });

  it('spawns the next occurrence in the same series for recurring tasks', () => {
    const task = makeTask({ recurrenceIntervalDays: 3, notes: 'old note' });
    const { completed, spawned } = completeTask(task, NOW, () => 't2');
    expect(spawned).toMatchObject({ id: 't2', seriesId: 's1', isCompleted: false, notes: undefined });
    expect(new Date(spawned!.dueDate).getDate()).toBe(10);
    expect(completed.spawnedTaskId).toBe('t2');
  });

  it('is idempotent for an already completed task', () => {
    const done = makeTask({ isCompleted: true, completedAt: NOW.toISOString() });
    expect(completeTask(done, NOW, () => 'x')).toEqual({ completed: done });
  });

  it('undo restores the task and removes the untouched spawned occurrence', () => {
    const { completed, spawned } = completeTask(makeTask({ recurrenceIntervalDays: 3 }), NOW, () => 't2');
    const { restored, deleteTaskId } = undoCompletion(completed, spawned, NOW);
    expect(restored.isCompleted).toBe(false);
    expect(restored.completedAt).toBeUndefined();
    expect(restored.spawnedTaskId).toBeUndefined();
    expect(deleteTaskId).toBe('t2');
  });

  it('undo keeps a spawned occurrence that the user has since edited', () => {
    const { completed, spawned } = completeTask(makeTask({ recurrenceIntervalDays: 3 }), NOW, () => 't2');
    const edited = { ...spawned!, title: 'Changed', updatedAt: new Date(NOW.getTime() + 1000).toISOString() };
    expect(undoCompletion(completed, edited, NOW).deleteTaskId).toBeUndefined();
  });
});

describe('filterTasks', () => {
  const tasks = [
    makeTask({ id: 'late', dueDate: at(2).toISOString() }),
    makeTask({ id: 'today', dueDate: at(7, 18).toISOString() }),
    makeTask({ id: 'soon', dueDate: at(9).toISOString() }),
    makeTask({ id: 'done-old', isCompleted: true, completedAt: at(1).toISOString() }),
    makeTask({ id: 'done-new', isCompleted: true, completedAt: at(6).toISOString() }),
  ];

  it('filters and sorts each segment', () => {
    expect(filterTasks(tasks, 'upcoming', NOW).map((t) => t.id)).toEqual(['today', 'soon']);
    expect(filterTasks(tasks, 'overdue', NOW).map((t) => t.id)).toEqual(['late']);
    expect(filterTasks(tasks, 'completed', NOW).map((t) => t.id)).toEqual(['done-new', 'done-old']);
    expect(filterTasks(tasks, 'all', NOW)).toHaveLength(5);
  });
});
