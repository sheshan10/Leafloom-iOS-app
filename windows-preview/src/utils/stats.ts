import type { CareTask, Plant, PlantCategory } from '../types/models';
import { addDays, calendarDaysBetween, startOfMonth, startOfWeek } from './dates';
import { careStatus } from './recurrence';

export interface DashboardSummary {
  totalPlants: number;
  favorites: number;
  needsAttention: Plant[];
  dueToday: CareTask[];
  overdue: CareTask[];
  upcomingWeek: CareTask[];
  completedThisWeek: number;
  /** completed this week ÷ (completed this week + still-open tasks due this week or overdue). */
  weeklyProgress: number;
  /** Share of plants with no overdue care. A scheduling measure, not a botanical health score. */
  onSchedulePercent: number;
  recentlyAdded: Plant[];
}

export const dashboardSummary = (plants: Plant[], tasks: CareTask[], now = new Date()): DashboardSummary => {
  const weekStart = startOfWeek(now);
  const weekEnd = addDays(weekStart, 7);
  const open = tasks.filter((t) => !t.isCompleted);
  const overdue = open.filter((t) => careStatus(t, now) === 'overdue');
  const dueToday = open.filter((t) => careStatus(t, now) === 'dueToday');
  const upcomingWeek = open
    .filter((t) => {
      const d = calendarDaysBetween(now, new Date(t.dueDate));
      return d >= 0 && d <= 7;
    })
    .sort((a, b) => a.dueDate.localeCompare(b.dueDate));

  const completedThisWeek = tasks.filter(
    (t) => t.isCompleted && t.completedAt && new Date(t.completedAt) >= weekStart && new Date(t.completedAt) < weekEnd,
  ).length;
  const openThisWeek = open.filter((t) => new Date(t.dueDate) < weekEnd).length;
  const denominator = completedThisWeek + openThisWeek;

  const attentionIds = new Set([...overdue, ...dueToday].map((t) => t.plantId).filter(Boolean) as string[]);
  const overdueIds = new Set(overdue.map((t) => t.plantId).filter(Boolean) as string[]);

  return {
    totalPlants: plants.length,
    favorites: plants.filter((p) => p.isFavorite).length,
    needsAttention: plants.filter((p) => attentionIds.has(p.id)),
    dueToday,
    overdue,
    upcomingWeek,
    completedThisWeek,
    weeklyProgress: denominator === 0 ? 0 : completedThisWeek / denominator,
    onSchedulePercent: plants.length === 0 ? 0 : Math.round(((plants.length - overdueIds.size) / plants.length) * 100),
    recentlyAdded: [...plants].sort((a, b) => b.dateAdded.localeCompare(a.dateAdded)).slice(0, 5),
  };
};

export const plantsByCategory = (plants: Plant[]) => {
  const counts = new Map<PlantCategory, number>();
  plants.forEach((p) => counts.set(p.category, (counts.get(p.category) ?? 0) + 1));
  return [...counts.entries()].map(([category, count]) => ({ category, count })).sort((a, b) => b.count - a.count);
};

/** Plants added per month for the last `months` months, oldest first. */
export const additionsByMonth = (plants: Plant[], now = new Date(), months = 6) => {
  const first = startOfMonth(now);
  return Array.from({ length: months }, (_, i) => {
    const start = new Date(first.getFullYear(), first.getMonth() - (months - 1 - i), 1);
    const end = new Date(start.getFullYear(), start.getMonth() + 1, 1);
    return {
      label: new Intl.DateTimeFormat(undefined, { month: 'short' }).format(start),
      start,
      count: plants.filter((p) => {
        const d = new Date(p.dateAdded);
        return d >= start && d < end;
      }).length,
    };
  });
};

/** Completed tasks per ISO week for the last `weeks` weeks, oldest first. */
export const completionTrend = (tasks: CareTask[], now = new Date(), weeks = 8) => {
  const current = startOfWeek(now);
  return Array.from({ length: weeks }, (_, i) => {
    const start = addDays(current, -7 * (weeks - 1 - i));
    const end = addDays(start, 7);
    return {
      label: new Intl.DateTimeFormat(undefined, { day: 'numeric', month: 'short' }).format(start),
      start,
      count: tasks.filter((t) => t.completedAt && new Date(t.completedAt) >= start && new Date(t.completedAt) < end)
        .length,
    };
  });
};

export const careByCategory = (tasks: CareTask[]) => {
  const counts = new Map<string, number>();
  tasks.filter((t) => t.isCompleted).forEach((t) => counts.set(t.category, (counts.get(t.category) ?? 0) + 1));
  return [...counts.entries()].map(([category, count]) => ({ category, count }));
};
