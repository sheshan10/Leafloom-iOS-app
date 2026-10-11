import type { CareTask, Plant } from '../types/models';

export const NOW = new Date(2026, 9, 7, 10, 0, 0); // Wednesday 7 Oct 2026, 10:00 local

export const makePlant = (overrides: Partial<Plant> = {}): Plant => ({
  id: 'p1',
  name: 'Monty',
  category: 'foliage',
  identificationStatus: 'identified',
  dateAdded: NOW.toISOString(),
  tags: [],
  isFavorite: false,
  isSample: false,
  createdAt: NOW.toISOString(),
  updatedAt: NOW.toISOString(),
  ...overrides,
});

export const makeTask = (overrides: Partial<CareTask> = {}): CareTask => ({
  id: 't1',
  seriesId: 's1',
  plantId: 'p1',
  title: 'Water Monty',
  category: 'watering',
  dueDate: new Date(2026, 9, 7, 9, 0).toISOString(),
  isCompleted: false,
  isSample: false,
  createdAt: new Date(2026, 9, 1).toISOString(),
  updatedAt: new Date(2026, 9, 1).toISOString(),
  ...overrides,
});
