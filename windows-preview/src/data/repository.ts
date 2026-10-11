import { openDB, type DBSchema, type IDBPDatabase } from 'idb';
import {
  defaultPreferences,
  type CareTask,
  type IdentificationRecord,
  type JournalEntry,
  type Plant,
  type Preferences,
} from '../types/models';

/**
 * Browser persistence for the preview. This dataset is completely separate from the native
 * Core Data store — nothing is synchronised between the two applications.
 */
interface LeafLoomDB extends DBSchema {
  plants: { key: string; value: Plant };
  tasks: { key: string; value: CareTask; indexes: { byPlant: string } };
  journal: { key: string; value: JournalEntry; indexes: { byPlant: string } };
  identifications: { key: string; value: IdentificationRecord };
  meta: { key: string; value: Preferences };
}

export interface Snapshot {
  plants: Plant[];
  tasks: CareTask[];
  journal: JournalEntry[];
  identifications: IdentificationRecord[];
  preferences: Preferences;
}

export interface SeedData {
  plants: Plant[];
  tasks: CareTask[];
  journal: JournalEntry[];
}

export class PersistenceError extends Error {
  constructor(message: string, readonly cause?: unknown) {
    super(message);
  }
}

const PREFS_KEY = 'preferences';

export class Repository {
  private dbPromise: Promise<IDBPDatabase<LeafLoomDB>>;

  constructor(dbName = 'leafloom-preview') {
    this.dbPromise = openDB<LeafLoomDB>(dbName, 1, {
      upgrade(db) {
        db.createObjectStore('plants', { keyPath: 'id' });
        db.createObjectStore('tasks', { keyPath: 'id' }).createIndex('byPlant', 'plantId');
        db.createObjectStore('journal', { keyPath: 'id' }).createIndex('byPlant', 'plantId');
        db.createObjectStore('identifications', { keyPath: 'id' });
        db.createObjectStore('meta');
      },
    });
  }

  private async run<T>(label: string, op: (db: IDBPDatabase<LeafLoomDB>) => Promise<T>): Promise<T> {
    try {
      return await op(await this.dbPromise);
    } catch (error) {
      console.error(`[LeafLoom] persistence failed: ${label}`, error);
      throw new PersistenceError(`Could not ${label}. Your previous data is unchanged.`, error);
    }
  }

  loadAll(): Promise<Snapshot> {
    return this.run('load your data', async (db) => {
      const [plants, tasks, journal, identifications, prefs] = await Promise.all([
        db.getAll('plants'),
        db.getAll('tasks'),
        db.getAll('journal'),
        db.getAll('identifications'),
        db.get('meta', PREFS_KEY),
      ]);
      return { plants, tasks, journal, identifications, preferences: { ...defaultPreferences, ...prefs } };
    });
  }

  putPlant(plant: Plant) {
    return this.run('save the plant', async (db) => {
      await db.put('plants', plant);
    });
  }

  /** Plant + its tasks + its journal entries are deleted together; identification history is kept but unlinked. */
  deletePlantCascade(plantId: string) {
    return this.run('delete the plant', async (db) => {
      const tx = db.transaction(['plants', 'tasks', 'journal', 'identifications'], 'readwrite');
      const taskKeys = await tx.objectStore('tasks').index('byPlant').getAllKeys(plantId);
      const journalKeys = await tx.objectStore('journal').index('byPlant').getAllKeys(plantId);
      const ids = await tx.objectStore('identifications').getAll();
      await Promise.all([
        tx.objectStore('plants').delete(plantId),
        ...taskKeys.map((k) => tx.objectStore('tasks').delete(k)),
        ...journalKeys.map((k) => tx.objectStore('journal').delete(k)),
        ...ids
          .filter((r) => r.plantId === plantId)
          .map((r) => tx.objectStore('identifications').put({ ...r, plantId: undefined })),
      ]);
      await tx.done;
      return { deletedTaskIds: taskKeys, deletedJournalIds: journalKeys };
    });
  }

  putTasks(tasks: CareTask[]) {
    return this.run('save the care task', async (db) => {
      const tx = db.transaction('tasks', 'readwrite');
      await Promise.all([...tasks.map((t) => tx.store.put(t)), tx.done]);
    });
  }

  /** Saves and deletes in one transaction so completion + recurrence (or undo) is atomic. */
  writeTasks(put: CareTask[], remove: string[] = []) {
    return this.run('update care tasks', async (db) => {
      const tx = db.transaction('tasks', 'readwrite');
      await Promise.all([...put.map((t) => tx.store.put(t)), ...remove.map((id) => tx.store.delete(id)), tx.done]);
    });
  }

  deleteTask(id: string) {
    return this.writeTasks([], [id]);
  }

  putJournal(entry: JournalEntry) {
    return this.run('save the journal entry', async (db) => {
      await db.put('journal', entry);
    });
  }

  deleteJournal(id: string) {
    return this.run('delete the journal entry', async (db) => {
      await db.delete('journal', id);
    });
  }

  putIdentification(record: IdentificationRecord) {
    return this.run('save the identification', async (db) => {
      await db.put('identifications', record);
    });
  }

  savePreferences(prefs: Preferences) {
    return this.run('save your preferences', async (db) => {
      await db.put('meta', prefs, PREFS_KEY);
    });
  }

  /** Clears every store and optionally writes seed data, atomically. */
  replaceAll(seed: SeedData | undefined, prefs: Preferences) {
    return this.run('reset the data', async (db) => {
      const tx = db.transaction(['plants', 'tasks', 'journal', 'identifications', 'meta'], 'readwrite');
      await Promise.all([
        tx.objectStore('plants').clear(),
        tx.objectStore('tasks').clear(),
        tx.objectStore('journal').clear(),
        tx.objectStore('identifications').clear(),
      ]);
      if (seed) {
        await Promise.all([
          ...seed.plants.map((p) => tx.objectStore('plants').put(p)),
          ...seed.tasks.map((t) => tx.objectStore('tasks').put(t)),
          ...seed.journal.map((j) => tx.objectStore('journal').put(j)),
        ]);
      }
      await tx.objectStore('meta').put(prefs, PREFS_KEY);
      await tx.done;
    });
  }

  async close() {
    (await this.dbPromise).close();
  }
}
