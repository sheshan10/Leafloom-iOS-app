import type { CareTask, Plant, PlantCategory } from '../types/models';

export type PlantSort = 'recent' | 'alphabetical' | 'nextCare';

export interface PlantQuery {
  search: string;
  categories: PlantCategory[];
  location?: string;
  favoritesOnly: boolean;
  sort: PlantSort;
}

export const emptyQuery: PlantQuery = { search: '', categories: [], favoritesOnly: false, sort: 'recent' };

export const isQueryActive = (q: PlantQuery) =>
  q.search.trim() !== '' || q.categories.length > 0 || !!q.location || q.favoritesOnly;

/** Earliest incomplete due date per plant id, computed once per task-list change. */
export const nextCareIndex = (tasks: CareTask[]) => {
  const index = new Map<string, number>();
  for (const t of tasks) {
    if (t.isCompleted || !t.plantId) continue;
    const due = new Date(t.dueDate).getTime();
    const current = index.get(t.plantId);
    if (current === undefined || due < current) index.set(t.plantId, due);
  }
  return index;
};

const normalise = (s?: string) => (s ?? '').toLocaleLowerCase().normalize('NFKD').replace(/\p{M}/gu, '').trim();

export const matchesSearch = (plant: Plant, search: string) => {
  const needle = normalise(search);
  if (!needle) return true;
  return [plant.name, plant.commonName, plant.scientificName, ...plant.tags].some((field) =>
    normalise(field).includes(needle),
  );
};

export const applyPlantQuery = (plants: Plant[], query: PlantQuery, nextCare: Map<string, number>) => {
  const filtered = plants.filter(
    (p) =>
      matchesSearch(p, query.search) &&
      (query.categories.length === 0 || query.categories.includes(p.category)) &&
      (!query.location || p.location === query.location) &&
      (!query.favoritesOnly || p.isFavorite),
  );
  const byName = (a: Plant, b: Plant) => a.name.localeCompare(b.name, undefined, { sensitivity: 'base' });
  switch (query.sort) {
    case 'alphabetical':
      return filtered.sort(byName);
    case 'nextCare':
      return filtered.sort((a, b) => {
        const da = nextCare.get(a.id) ?? Number.POSITIVE_INFINITY;
        const db = nextCare.get(b.id) ?? Number.POSITIVE_INFINITY;
        return da === db ? byName(a, b) : da - db;
      });
    default:
      return filtered.sort((a, b) => new Date(b.dateAdded).getTime() - new Date(a.dateAdded).getTime());
  }
};

export const distinctLocations = (plants: Plant[]) =>
  [...new Set(plants.map((p) => p.location?.trim()).filter((l): l is string => !!l))].sort((a, b) =>
    a.localeCompare(b),
  );
