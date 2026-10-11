import { NOW, makePlant, makeTask } from '../test/fixtures';
import { applyPlantQuery, distinctLocations, emptyQuery, isQueryActive, matchesSearch, nextCareIndex } from './filters';

const plants = [
  makePlant({ id: 'a', name: 'Monty', commonName: 'Monstera', category: 'foliage', location: 'Living room', dateAdded: '2026-01-01T00:00:00.000Z', tags: ['big'] }),
  makePlant({ id: 'b', name: 'aloe', scientificName: 'Aloe vera', category: 'succulent', location: 'Kitchen', isFavorite: true, dateAdded: '2026-03-01T00:00:00.000Z' }),
  makePlant({ id: 'c', name: 'Basil', category: 'herb', location: 'Kitchen', dateAdded: '2026-02-01T00:00:00.000Z' }),
];

describe('matchesSearch', () => {
  it('matches name, common name, scientific name and tags case-insensitively', () => {
    expect(matchesSearch(plants[0], 'MONST')).toBe(true);
    expect(matchesSearch(plants[1], 'vera')).toBe(true);
    expect(matchesSearch(plants[0], 'big')).toBe(true);
    expect(matchesSearch(plants[2], 'rose')).toBe(false);
  });

  it('ignores diacritics and blank searches', () => {
    expect(matchesSearch(makePlant({ name: 'Crème Fern' }), 'creme')).toBe(true);
    expect(matchesSearch(plants[2], '   ')).toBe(true);
  });
});

describe('applyPlantQuery', () => {
  const index = nextCareIndex([
    makeTask({ plantId: 'c', dueDate: '2026-10-08T09:00:00.000Z' }),
    makeTask({ plantId: 'a', dueDate: '2026-10-20T09:00:00.000Z' }),
    makeTask({ plantId: 'a', dueDate: '2026-10-01T09:00:00.000Z', isCompleted: true }),
  ]);

  it('sorts by most recently added by default', () => {
    expect(applyPlantQuery([...plants], emptyQuery, index).map((p) => p.id)).toEqual(['b', 'c', 'a']);
  });

  it('sorts alphabetically ignoring case', () => {
    expect(applyPlantQuery([...plants], { ...emptyQuery, sort: 'alphabetical' }, index).map((p) => p.name)).toEqual(['aloe', 'Basil', 'Monty']);
  });

  it('sorts by next care, ignoring completed tasks and placing plants without tasks last', () => {
    expect(applyPlantQuery([...plants], { ...emptyQuery, sort: 'nextCare' }, index).map((p) => p.id)).toEqual(['c', 'a', 'b']);
  });

  it('combines category, location and favourite filters', () => {
    const q = { ...emptyQuery, categories: ['succulent' as const, 'herb' as const], location: 'Kitchen' };
    expect(applyPlantQuery([...plants], q, index).map((p) => p.id)).toEqual(['b', 'c']);
    expect(applyPlantQuery([...plants], { ...q, favoritesOnly: true }, index).map((p) => p.id)).toEqual(['b']);
    expect(isQueryActive(q)).toBe(true);
    expect(isQueryActive(emptyQuery)).toBe(false);
  });
});

describe('distinctLocations', () => {
  it('returns sorted unique trimmed locations', () => {
    expect(distinctLocations([...plants, makePlant({ location: ' Kitchen ' }), makePlant({ location: '' })])).toEqual(['Kitchen', 'Living room']);
  });
});

it('fixture date is stable', () => {
  expect(NOW.getDay()).toBe(3);
});
