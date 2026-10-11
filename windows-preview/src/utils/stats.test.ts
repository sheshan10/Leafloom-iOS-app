import { NOW, makePlant, makeTask } from '../test/fixtures';
import { additionsByMonth, careByCategory, completionTrend, dashboardSummary, plantsByCategory } from './stats';

const at = (d: number, h = 9) => new Date(2026, 9, d, h).toISOString();

describe('dashboardSummary', () => {
  it('returns zeros for an empty collection', () => {
    const s = dashboardSummary([], [], NOW);
    expect(s).toMatchObject({ totalPlants: 0, weeklyProgress: 0, onSchedulePercent: 0, completedThisWeek: 0 });
  });

  it('computes weekly progress, attention and on-schedule share', () => {
    const plants = [makePlant({ id: 'a', isFavorite: true }), makePlant({ id: 'b' }), makePlant({ id: 'c' }), makePlant({ id: 'd' })];
    const tasks = [
      makeTask({ id: '1', plantId: 'a', dueDate: at(3) }), // overdue
      makeTask({ id: '2', plantId: 'b', dueDate: at(7, 18) }), // due today
      makeTask({ id: '3', plantId: 'c', dueDate: at(10) }), // upcoming, this week (week ends Mon 12)
      makeTask({ id: '4', plantId: 'c', dueDate: at(20) }), // later
      makeTask({ id: '5', plantId: 'd', isCompleted: true, completedAt: at(6) }), // completed this week
      makeTask({ id: '6', plantId: 'd', isCompleted: true, completedAt: at(2) }), // completed last week
    ];
    const s = dashboardSummary(plants, tasks, NOW);
    expect(s.totalPlants).toBe(4);
    expect(s.favorites).toBe(1);
    expect(s.overdue.map((t) => t.id)).toEqual(['1']);
    expect(s.dueToday.map((t) => t.id)).toEqual(['2']);
    expect(s.upcomingWeek.map((t) => t.id)).toEqual(['2', '3']);
    expect(s.needsAttention.map((p) => p.id)).toEqual(['a', 'b']);
    expect(s.completedThisWeek).toBe(1);
    // 1 completed / (1 completed + 3 open due before next Monday incl. overdue)
    expect(s.weeklyProgress).toBeCloseTo(1 / 4);
    expect(s.onSchedulePercent).toBe(75);
  });
});

describe('chart aggregations', () => {
  it('counts plants per category, most common first', () => {
    const r = plantsByCategory([makePlant({ category: 'herb' }), makePlant({ category: 'foliage' }), makePlant({ category: 'herb' })]);
    expect(r[0]).toEqual({ category: 'herb', count: 2 });
  });

  it('buckets additions into the last six months', () => {
    const r = additionsByMonth([makePlant({ dateAdded: at(1) }), makePlant({ dateAdded: new Date(2026, 4, 15).toISOString() }), makePlant({ dateAdded: new Date(2025, 0, 1).toISOString() })], NOW);
    expect(r).toHaveLength(6);
    expect(r[5].count).toBe(1);
    expect(r[0].start.getMonth()).toBe(4);
    expect(r[0].count).toBe(1);
  });

  it('buckets completions into the last eight weeks', () => {
    const r = completionTrend([makeTask({ completedAt: at(6), isCompleted: true }), makeTask({ completedAt: at(1), isCompleted: true })], NOW);
    expect(r).toHaveLength(8);
    expect(r[7].count).toBe(1);
    expect(r[6].count).toBe(1);
  });

  it('counts completed care by category', () => {
    const r = careByCategory([makeTask({ isCompleted: true }), makeTask({ isCompleted: true, category: 'fertilizing' }), makeTask()]);
    expect(r).toEqual(expect.arrayContaining([{ category: 'watering', count: 1 }, { category: 'fertilizing', count: 1 }]));
  });
});
