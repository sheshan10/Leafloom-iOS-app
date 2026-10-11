import { NOW, makePlant, makeTask } from '../test/fixtures';
import { defaultPreferences } from '../types/models';
import { Repository } from './repository';
import { buildSampleData } from './sampleData';

let dbCounter = 0;
const freshRepo = () => new Repository(`repo-test-${++dbCounter}`);

describe('Repository (IndexedDB via fake-indexeddb)', () => {
  it('starts empty with default preferences', async () => {
    const repo = freshRepo();
    const snap = await repo.loadAll();
    expect(snap.plants).toEqual([]);
    expect(snap.preferences).toEqual(defaultPreferences);
    await repo.close();
  });

  it('creates, updates and reloads plants', async () => {
    const repo = freshRepo();
    await repo.putPlant(makePlant({ id: 'a', name: 'Monty' }));
    await repo.putPlant(makePlant({ id: 'a', name: 'Monty II' }));
    const snap = await repo.loadAll();
    expect(snap.plants).toHaveLength(1);
    expect(snap.plants[0].name).toBe('Monty II');
    await repo.close();
  });

  it('cascades plant deletion to tasks and journal and unlinks identifications', async () => {
    const repo = freshRepo();
    await repo.putPlant(makePlant({ id: 'a' }));
    await repo.putPlant(makePlant({ id: 'b' }));
    await repo.putTasks([makeTask({ id: 't1', plantId: 'a' }), makeTask({ id: 't2', plantId: 'b' }), makeTask({ id: 't3', plantId: undefined })]);
    await repo.putJournal({ id: 'j1', plantId: 'a', entryDate: NOW.toISOString(), notes: 'x', createdAt: '', updatedAt: '' });
    await repo.putIdentification({ id: 'i1', dateCreated: '', predictedLabel: 'Monstera', modelIdentifier: 'demo', isDemoResult: true, plantId: 'a' });

    const result = await repo.deletePlantCascade('a');
    expect(result.deletedTaskIds).toEqual(['t1']);
    expect(result.deletedJournalIds).toEqual(['j1']);

    const snap = await repo.loadAll();
    expect(snap.plants.map((p) => p.id)).toEqual(['b']);
    expect(snap.tasks.map((t) => t.id).sort()).toEqual(['t2', 't3']);
    expect(snap.journal).toEqual([]);
    expect(snap.identifications).toHaveLength(1);
    expect(snap.identifications[0].plantId).toBeUndefined();
    await repo.close();
  });

  it('writes and deletes tasks atomically in one call', async () => {
    const repo = freshRepo();
    await repo.putTasks([makeTask({ id: 'old' })]);
    await repo.writeTasks([makeTask({ id: 'new' })], ['old']);
    expect((await repo.loadAll()).tasks.map((t) => t.id)).toEqual(['new']);
    await repo.close();
  });

  it('replaceAll seeds sample data and persists preferences; erase leaves stores empty', async () => {
    const repo = freshRepo();
    const seed = buildSampleData(NOW);
    await repo.replaceAll(seed, { ...defaultPreferences, sampleDataSeeded: true, theme: 'dark' });
    let snap = await repo.loadAll();
    expect(snap.plants).toHaveLength(seed.plants.length);
    expect(snap.tasks).toHaveLength(seed.tasks.length);
    expect(snap.preferences.theme).toBe('dark');

    await repo.replaceAll(undefined, snap.preferences);
    snap = await repo.loadAll();
    expect(snap.plants).toEqual([]);
    expect(snap.tasks).toEqual([]);
    expect(snap.preferences.sampleDataSeeded).toBe(true);
    await repo.close();
  });
});
