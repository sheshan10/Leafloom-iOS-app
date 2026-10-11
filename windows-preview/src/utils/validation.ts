import type { CareTaskDraft, JournalDraft, PlantDraft } from '../types/models';
import { startOfDay } from './dates';

export type ValidationErrors<T> = Partial<Record<keyof T, string>>;

export const NAME_MAX = 60;
export const NOTES_MAX = 1000;

const trimOrUndefined = (s?: string) => {
  const t = s?.trim().replace(/\s+/g, ' ');
  return t ? t : undefined;
};

export const normaliseTags = (tags: string[]) => {
  const seen = new Set<string>();
  return tags
    .map((t) => t.trim().toLowerCase())
    .filter((t) => t && !seen.has(t) && seen.add(t))
    .slice(0, 10);
};

export const parseTags = (input: string) => normaliseTags(input.split(','));

const intervalError = (value?: number) => {
  if (value === undefined) return undefined;
  if (!Number.isInteger(value) || value < 1 || value > 365) return 'Enter a whole number of days between 1 and 365.';
  return undefined;
};

export const normalisePlantDraft = (d: PlantDraft): PlantDraft => ({
  ...d,
  name: d.name.trim().replace(/\s+/g, ' '),
  commonName: trimOrUndefined(d.commonName),
  scientificName: trimOrUndefined(d.scientificName),
  location: trimOrUndefined(d.location),
  soilPreference: trimOrUndefined(d.soilPreference),
  notes: d.notes?.trim() || undefined,
  tags: normaliseTags(d.tags),
});

export const validatePlant = (d: PlantDraft, now = new Date()): ValidationErrors<PlantDraft> => {
  const errors: ValidationErrors<PlantDraft> = {};
  const name = d.name.trim();
  if (!name) errors.name = 'Give your plant a name.';
  else if (name.length > NAME_MAX) errors.name = `Keep the name under ${NAME_MAX} characters.`;
  if (!d.category) errors.category = 'Choose a category.';
  const w = intervalError(d.wateringIntervalDays);
  if (w) errors.wateringIntervalDays = w;
  const f = intervalError(d.fertilizingIntervalDays);
  if (f) errors.fertilizingIntervalDays = f;
  if (d.acquisitionDate && startOfDay(new Date(d.acquisitionDate)) > startOfDay(now)) {
    errors.acquisitionDate = 'The acquisition date cannot be in the future.';
  }
  if ((d.notes?.length ?? 0) > NOTES_MAX) errors.notes = `Notes can be up to ${NOTES_MAX} characters.`;
  return errors;
};

export const validateTask = (d: CareTaskDraft): ValidationErrors<CareTaskDraft> => {
  const errors: ValidationErrors<CareTaskDraft> = {};
  if (!d.title.trim()) errors.title = 'Add a short title for this task.';
  else if (d.title.trim().length > NAME_MAX) errors.title = `Keep the title under ${NAME_MAX} characters.`;
  if (!d.dueDate || Number.isNaN(new Date(d.dueDate).getTime())) errors.dueDate = 'Choose a due date.';
  const r = intervalError(d.recurrenceIntervalDays);
  if (r) errors.recurrenceIntervalDays = r;
  return errors;
};

export const validateJournal = (d: JournalDraft, now = new Date()): ValidationErrors<JournalDraft> => {
  const errors: ValidationErrors<JournalDraft> = {};
  if (!d.plantId) errors.plantId = 'Choose which plant this entry is about.';
  if (!d.notes.trim()) errors.notes = 'Write a short note about what you observed.';
  else if (d.notes.length > NOTES_MAX) errors.notes = `Notes can be up to ${NOTES_MAX} characters.`;
  if (!d.entryDate) errors.entryDate = 'Choose a date.';
  else if (startOfDay(new Date(d.entryDate)) > startOfDay(now)) errors.entryDate = 'Journal entries cannot be dated in the future.';
  if (d.heightCm !== undefined && (Number.isNaN(d.heightCm) || d.heightCm <= 0 || d.heightCm > 1000)) {
    errors.heightCm = 'Height must be greater than 0 and at most 1000 cm.';
  }
  return errors;
};

export const hasErrors = (e: object) => Object.keys(e).length > 0;
