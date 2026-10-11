import { NOW } from '../test/fixtures';
import { lookupLabel, knowledgeBase } from './knowledge';
import { buildSampleData } from './sampleData';
import { hashString, simulateIdentification } from '../features/identify/simulatedIdentifier';

describe('sample data', () => {
  const seed = buildSampleData(NOW);

  it('creates eight flagged sample plants with unique ids', () => {
    expect(seed.plants).toHaveLength(8);
    expect(new Set(seed.plants.map((p) => p.id)).size).toBe(8);
    expect(seed.plants.every((p) => p.isSample)).toBe(true);
  });

  it('only references existing plants from tasks and journal entries', () => {
    const ids = new Set(seed.plants.map((p) => p.id));
    expect(seed.tasks.every((t) => !t.plantId || ids.has(t.plantId))).toBe(true);
    expect(seed.journal.every((j) => ids.has(j.plantId))).toBe(true);
  });

  it('is deterministic for a given clock', () => {
    const again = buildSampleData(NOW);
    expect(again.plants.map((p) => p.name)).toEqual(seed.plants.map((p) => p.name));
    expect(again.tasks.length).toBe(seed.tasks.length);
  });

  it('never creates a completed task without a completion date', () => {
    expect(seed.tasks.filter((t) => t.isCompleted).every((t) => !!t.completedAt)).toBe(true);
  });
});

describe('knowledge lookup (mirrors native LabelMapper)', () => {
  it('matches keys, common names, scientific names and aliases regardless of case and separators', () => {
    expect(lookupLabel('monstera_deliciosa')?.key).toBe('monstera_deliciosa');
    expect(lookupLabel('MONSTERA-DELICIOSA')?.key).toBe('monstera_deliciosa');
    const entry = knowledgeBase[1];
    expect(lookupLabel(entry.commonName)?.key).toBe(entry.key);
    expect(lookupLabel(entry.scientificName)?.key).toBe(entry.key);
    if (entry.aliases[0]) expect(lookupLabel(entry.aliases[0])?.key).toBe(entry.key);
  });

  it('returns undefined for unknown labels', () => {
    expect(lookupLabel('definitely not a plant')).toBeUndefined();
  });
});

describe('simulated identification', () => {
  it('is deterministic and never reports a confidence', () => {
    const a = simulateIdentification('data:image/jpeg;base64,AAAA');
    const b = simulateIdentification('data:image/jpeg;base64,AAAA');
    expect(a).toEqual(b);
    expect(a.kind).toBe('simulated');
    expect(a.confidence).toBeUndefined();
    expect(a.alternatives).toHaveLength(2);
  });

  it('maps bundled sample photos to their own plant', () => {
    expect(simulateIdentification('/images/plants/basil.jpg').top.entry?.key).toBe('ocimum_basilicum');
  });

  it('hashes strings stably', () => {
    expect(hashString('leafloom')).toBe(hashString('leafloom'));
    expect(hashString('leafloom')).not.toBe(hashString('leafloon'));
  });
});
