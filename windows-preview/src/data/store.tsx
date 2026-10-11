import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import {
  defaultPreferences,
  type CareTask,
  type CareTaskDraft,
  type IdentificationRecord,
  type JournalDraft,
  type JournalEntry,
  type Plant,
  type PlantDraft,
  type Preferences,
} from '../types/models';
import { addDays, startOfDay } from '../utils/dates';
import { newId } from '../utils/ids';
import { completeTask as completeRule, undoCompletion } from '../utils/recurrence';
import { normalisePlantDraft } from '../utils/validation';
import { Repository, type Snapshot } from './repository';
import { buildSampleData } from './sampleData';

export interface AddPlantOptions {
  /** Creates recurring watering / fertilising tasks from the plant's intervals. */
  createCareSchedule: boolean;
  reminderHour: number;
}

interface DataActions {
  addPlant(draft: PlantDraft, options?: AddPlantOptions): Promise<Plant>;
  updatePlant(id: string, draft: PlantDraft): Promise<Plant>;
  deletePlant(id: string): Promise<void>;
  toggleFavorite(id: string): Promise<boolean>;
  addTask(draft: CareTaskDraft): Promise<CareTask>;
  updateTask(id: string, draft: CareTaskDraft): Promise<CareTask>;
  deleteTask(id: string): Promise<void>;
  completeTask(id: string): Promise<{ spawned?: CareTask }>;
  undoComplete(id: string): Promise<void>;
  addJournal(draft: JournalDraft): Promise<JournalEntry>;
  updateJournal(id: string, draft: JournalDraft): Promise<JournalEntry>;
  deleteJournal(id: string): Promise<void>;
  saveIdentification(record: Omit<IdentificationRecord, 'id' | 'dateCreated'>): Promise<IdentificationRecord>;
  linkIdentification(id: string, plantId: string): Promise<void>;
  updatePreferences(patch: Partial<Preferences>): Promise<void>;
  resetToSampleData(): Promise<void>;
  eraseAllData(): Promise<void>;
}

export interface DataState extends Snapshot {
  status: 'loading' | 'ready' | 'error';
  loadError?: string;
}

interface DataContextValue extends DataState {
  actions: DataActions;
  reload(): Promise<void>;
}

const DataContext = createContext<DataContextValue | null>(null);

const emptySnapshot: Snapshot = { plants: [], tasks: [], journal: [], identifications: [], preferences: defaultPreferences };

export function DataProvider({ children, dbName, now }: { children: ReactNode; dbName?: string; now?: () => Date }) {
  const repoRef = useRef<Repository | null>(null);
  if (!repoRef.current) repoRef.current = new Repository(dbName);
  const repo = repoRef.current;
  const clock = useMemo(() => now ?? (() => new Date()), [now]);

  const [state, setState] = useState<DataState>({ ...emptySnapshot, status: 'loading' });
  // A ref mirror lets actions read the latest snapshot without re-creating callbacks.
  const snap = useRef<Snapshot>(emptySnapshot);
  const commit = useCallback((next: Snapshot) => {
    snap.current = next;
    setState({ ...next, status: 'ready' });
  }, []);

  const load = useCallback(async () => {
    try {
      let data = await repo.loadAll();
      if (!data.preferences.sampleDataSeeded) {
        // First launch only: the flag stops sample data being duplicated on every load.
        const seed = buildSampleData(clock());
        const preferences = { ...data.preferences, sampleDataSeeded: true };
        await repo.replaceAll(seed, preferences);
        data = { ...seed, identifications: [], preferences };
      }
      commit(data);
    } catch (e) {
      setState((s) => ({ ...s, status: 'error', loadError: e instanceof Error ? e.message : 'Unknown error' }));
    }
  }, [repo, clock, commit]);

  useEffect(() => {
    void load();
  }, [load]);

  const actions = useMemo<DataActions>(() => {
    const stamp = () => clock().toISOString();
    const replaceIn = <T extends { id: string }>(list: T[], item: T) =>
      list.some((x) => x.id === item.id) ? list.map((x) => (x.id === item.id ? item : x)) : [...list, item];

    const buildSchedule = (plant: Plant, hour: number): CareTask[] => {
      const out: CareTask[] = [];
      const make = (category: CareTask['category'], interval: number, title: string, firstInDays: number) => {
        const due = addDays(startOfDay(clock()), firstInDays);
        due.setHours(hour, 0, 0, 0);
        out.push({
          id: newId(),
          seriesId: newId(),
          plantId: plant.id,
          title,
          category,
          dueDate: due.toISOString(),
          isCompleted: false,
          recurrenceIntervalDays: interval,
          isSample: false,
          createdAt: stamp(),
          updatedAt: stamp(),
        });
      };
      if (plant.wateringIntervalDays) make('watering', plant.wateringIntervalDays, `Water ${plant.name}`, 1);
      if (plant.fertilizingIntervalDays)
        make('fertilizing', plant.fertilizingIntervalDays, `Fertilise ${plant.name}`, plant.fertilizingIntervalDays);
      return out;
    };

    return {
      async addPlant(draft, options) {
        const d = normalisePlantDraft(draft);
        const now = stamp();
        const plant: Plant = { ...d, id: newId(), dateAdded: d.dateAdded ?? now, isSample: false, createdAt: now, updatedAt: now };
        await repo.putPlant(plant);
        const schedule = options?.createCareSchedule ? buildSchedule(plant, options.reminderHour) : [];
        if (schedule.length) await repo.putTasks(schedule);
        commit({ ...snap.current, plants: [...snap.current.plants, plant], tasks: [...snap.current.tasks, ...schedule] });
        return plant;
      },
      async updatePlant(id, draft) {
        const existing = snap.current.plants.find((p) => p.id === id);
        if (!existing) throw new Error('This plant no longer exists.');
        const d = normalisePlantDraft(draft);
        const plant: Plant = { ...existing, ...d, id, dateAdded: existing.dateAdded, updatedAt: stamp() };
        await repo.putPlant(plant);
        commit({ ...snap.current, plants: replaceIn(snap.current.plants, plant) });
        return plant;
      },
      async deletePlant(id) {
        await repo.deletePlantCascade(id);
        const s = snap.current;
        commit({
          ...s,
          plants: s.plants.filter((p) => p.id !== id),
          tasks: s.tasks.filter((t) => t.plantId !== id),
          journal: s.journal.filter((j) => j.plantId !== id),
          identifications: s.identifications.map((r) => (r.plantId === id ? { ...r, plantId: undefined } : r)),
        });
      },
      async toggleFavorite(id) {
        const existing = snap.current.plants.find((p) => p.id === id);
        if (!existing) throw new Error('This plant no longer exists.');
        const plant = { ...existing, isFavorite: !existing.isFavorite, updatedAt: stamp() };
        await repo.putPlant(plant);
        commit({ ...snap.current, plants: replaceIn(snap.current.plants, plant) });
        return plant.isFavorite;
      },
      async addTask(draft) {
        const now = stamp();
        const task: CareTask = {
          ...draft,
          title: draft.title.trim(),
          descriptionText: draft.descriptionText?.trim() || undefined,
          notes: draft.notes?.trim() || undefined,
          id: newId(),
          seriesId: newId(),
          isCompleted: false,
          isSample: false,
          createdAt: now,
          updatedAt: now,
        };
        await repo.putTasks([task]);
        commit({ ...snap.current, tasks: [...snap.current.tasks, task] });
        return task;
      },
      async updateTask(id, draft) {
        const existing = snap.current.tasks.find((t) => t.id === id);
        if (!existing) throw new Error('This task no longer exists.');
        const task: CareTask = {
          ...existing,
          ...draft,
          title: draft.title.trim(),
          descriptionText: draft.descriptionText?.trim() || undefined,
          notes: draft.notes?.trim() || undefined,
          updatedAt: stamp(),
        };
        await repo.putTasks([task]);
        commit({ ...snap.current, tasks: replaceIn(snap.current.tasks, task) });
        return task;
      },
      async deleteTask(id) {
        await repo.deleteTask(id);
        commit({ ...snap.current, tasks: snap.current.tasks.filter((t) => t.id !== id) });
      },
      async completeTask(id) {
        const task = snap.current.tasks.find((t) => t.id === id);
        if (!task) throw new Error('This task no longer exists.');
        const { completed, spawned } = completeRule(task, clock(), newId);
        const put = spawned ? [completed, spawned] : [completed];
        await repo.writeTasks(put);
        let tasks = replaceIn(snap.current.tasks, completed);
        if (spawned) tasks = [...tasks, spawned];
        commit({ ...snap.current, tasks });
        return { spawned };
      },
      async undoComplete(id) {
        const task = snap.current.tasks.find((t) => t.id === id);
        if (!task || !task.isCompleted) return;
        const spawned = snap.current.tasks.find((t) => t.id === task.spawnedTaskId);
        const { restored, deleteTaskId } = undoCompletion(task, spawned, clock());
        await repo.writeTasks([restored], deleteTaskId ? [deleteTaskId] : []);
        commit({
          ...snap.current,
          tasks: replaceIn(snap.current.tasks, restored).filter((t) => t.id !== deleteTaskId),
        });
      },
      async addJournal(draft) {
        const now = stamp();
        const entry: JournalEntry = { ...draft, notes: draft.notes.trim(), id: newId(), createdAt: now, updatedAt: now };
        await repo.putJournal(entry);
        commit({ ...snap.current, journal: [...snap.current.journal, entry] });
        return entry;
      },
      async updateJournal(id, draft) {
        const existing = snap.current.journal.find((j) => j.id === id);
        if (!existing) throw new Error('This entry no longer exists.');
        const entry: JournalEntry = { ...existing, ...draft, notes: draft.notes.trim(), updatedAt: stamp() };
        await repo.putJournal(entry);
        commit({ ...snap.current, journal: replaceIn(snap.current.journal, entry) });
        return entry;
      },
      async deleteJournal(id) {
        await repo.deleteJournal(id);
        commit({ ...snap.current, journal: snap.current.journal.filter((j) => j.id !== id) });
      },
      async saveIdentification(record) {
        const full: IdentificationRecord = { ...record, id: newId(), dateCreated: stamp() };
        await repo.putIdentification(full);
        commit({ ...snap.current, identifications: [...snap.current.identifications, full] });
        return full;
      },
      async linkIdentification(id, plantId) {
        const existing = snap.current.identifications.find((r) => r.id === id);
        if (!existing) return;
        const record = { ...existing, plantId };
        await repo.putIdentification(record);
        commit({ ...snap.current, identifications: replaceIn(snap.current.identifications, record) });
      },
      async updatePreferences(patch) {
        const preferences = { ...snap.current.preferences, ...patch };
        await repo.savePreferences(preferences);
        commit({ ...snap.current, preferences });
      },
      async resetToSampleData() {
        const seed = buildSampleData(clock());
        const preferences = { ...snap.current.preferences, sampleDataSeeded: true };
        await repo.replaceAll(seed, preferences);
        commit({ ...seed, identifications: [], preferences });
      },
      async eraseAllData() {
        const preferences = { ...snap.current.preferences, sampleDataSeeded: true };
        await repo.replaceAll(undefined, preferences);
        commit({ ...emptySnapshot, preferences });
      },
    };
  }, [repo, clock, commit]);

  const value = useMemo<DataContextValue>(() => ({ ...state, actions, reload: load }), [state, actions, load]);
  return <DataContext.Provider value={value}>{children}</DataContext.Provider>;
}

export function useData() {
  const ctx = useContext(DataContext);
  if (!ctx) throw new Error('useData must be used inside <DataProvider>');
  return ctx;
}
