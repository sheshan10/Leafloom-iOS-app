import { NOW } from '../test/fixtures';
import type { PlantDraft } from '../types/models';
import { hasErrors, normalisePlantDraft, parseTags, validateJournal, validatePlant, validateTask } from './validation';

const draft = (o: Partial<PlantDraft> = {}): PlantDraft => ({
  name: 'Monty',
  category: 'foliage',
  identificationStatus: 'identified',
  tags: [],
  isFavorite: false,
  ...o,
});

describe('validatePlant', () => {
  it('accepts a minimal valid plant', () => {
    expect(hasErrors(validatePlant(draft(), NOW))).toBe(false);
  });

  it('rejects empty, whitespace-only and over-long names', () => {
    expect(validatePlant(draft({ name: '   ' }), NOW).name).toBeDefined();
    expect(validatePlant(draft({ name: 'x'.repeat(61) }), NOW).name).toBeDefined();
    expect(validatePlant(draft({ name: 'x'.repeat(60) }), NOW).name).toBeUndefined();
  });

  it('enforces whole-number intervals between 1 and 365', () => {
    expect(validatePlant(draft({ wateringIntervalDays: 0 }), NOW).wateringIntervalDays).toBeDefined();
    expect(validatePlant(draft({ wateringIntervalDays: 366 }), NOW).wateringIntervalDays).toBeDefined();
    expect(validatePlant(draft({ fertilizingIntervalDays: 2.5 }), NOW).fertilizingIntervalDays).toBeDefined();
    expect(validatePlant(draft({ wateringIntervalDays: 365, fertilizingIntervalDays: 1 }), NOW)).toEqual({});
  });

  it('rejects future acquisition dates but allows today', () => {
    expect(validatePlant(draft({ acquisitionDate: new Date(2026, 9, 8).toISOString() }), NOW).acquisitionDate).toBeDefined();
    expect(validatePlant(draft({ acquisitionDate: new Date(2026, 9, 7, 23).toISOString() }), NOW).acquisitionDate).toBeUndefined();
  });

  it('limits notes length', () => {
    expect(validatePlant(draft({ notes: 'n'.repeat(1001) }), NOW).notes).toBeDefined();
  });
});

describe('normalisation', () => {
  it('trims and collapses whitespace and drops empty optionals', () => {
    const n = normalisePlantDraft(draft({ name: '  Big   Monty ', commonName: '  ', location: ' Hall ', notes: '  ' }));
    expect(n.name).toBe('Big Monty');
    expect(n.commonName).toBeUndefined();
    expect(n.location).toBe('Hall');
    expect(n.notes).toBeUndefined();
  });

  it('parses, lowercases, de-duplicates and caps tags', () => {
    expect(parseTags('Indoor, indoor ,  , Pet safe')).toEqual(['indoor', 'pet safe']);
    expect(parseTags(Array.from({ length: 15 }, (_, i) => `t${i}`).join(','))).toHaveLength(10);
  });
});

describe('validateTask', () => {
  it('requires a title and a valid due date', () => {
    const e = validateTask({ title: ' ', category: 'watering', dueDate: 'nope' });
    expect(e.title).toBeDefined();
    expect(e.dueDate).toBeDefined();
  });

  it('validates the optional recurrence interval', () => {
    const base = { title: 'Water', category: 'watering' as const, dueDate: NOW.toISOString() };
    expect(validateTask(base)).toEqual({});
    expect(validateTask({ ...base, recurrenceIntervalDays: 400 }).recurrenceIntervalDays).toBeDefined();
  });
});

describe('validateJournal', () => {
  const base = { plantId: 'p1', entryDate: NOW.toISOString(), notes: 'New leaf' };
  it('accepts a valid entry', () => expect(validateJournal(base, NOW)).toEqual({}));
  it('requires a plant and notes', () => {
    const e = validateJournal({ ...base, plantId: '', notes: ' ' }, NOW);
    expect(e.plantId).toBeDefined();
    expect(e.notes).toBeDefined();
  });
  it('rejects future dates and out-of-range heights', () => {
    expect(validateJournal({ ...base, entryDate: new Date(2026, 9, 9).toISOString() }, NOW).entryDate).toBeDefined();
    expect(validateJournal({ ...base, heightCm: 0 }, NOW).heightCm).toBeDefined();
    expect(validateJournal({ ...base, heightCm: 1001 }, NOW).heightCm).toBeDefined();
    expect(validateJournal({ ...base, heightCm: 42.5 }, NOW).heightCm).toBeUndefined();
  });
});
