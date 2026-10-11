import { knowledgeBase, type KnowledgeEntry } from '../../data/knowledge';

export interface SimulatedSuggestion {
  label: string;
  entry?: KnowledgeEntry;
}

export interface SimulatedResult {
  kind: 'simulated';
  modelIdentifier: 'preview-simulation';
  top: SimulatedSuggestion;
  alternatives: SimulatedSuggestion[];
  /** Simulated results never carry a confidence value. */
  confidence?: undefined;
}

/** Stable string hash (FNV-1a) so the same photo always gives the same demo suggestion. */
export const hashString = (s: string) => {
  let h = 0x811c9dc5;
  for (let i = 0; i < s.length; i += Math.max(1, Math.floor(s.length / 4096))) {
    h ^= s.charCodeAt(i);
    h = Math.imul(h, 0x01000193);
  }
  return h >>> 0;
};

/**
 * Demonstration only — this performs NO image analysis. For the bundled sample photos it returns the
 * plant the photo was generated for; for any other image it picks deterministically from the
 * knowledge base. The UI always labels these results as simulated.
 */
export function simulateIdentification(image: string): SimulatedResult {
  const sample = knowledgeBase.find((e) => e.image && image.endsWith(`/images/plants/${e.image}`));
  const pool = knowledgeBase;
  const start = sample ? pool.indexOf(sample) : hashString(image) % pool.length;
  const pick = (offset: number) => pool[(start + offset) % pool.length];
  const toSuggestion = (e: KnowledgeEntry): SimulatedSuggestion => ({ label: e.commonName, entry: e });
  return {
    kind: 'simulated',
    modelIdentifier: 'preview-simulation',
    top: toSuggestion(pick(0)),
    alternatives: [toSuggestion(pick(3)), toSuggestion(pick(7))],
  };
}

export class IdentificationError extends Error {}

export const SIMULATED_DELAY_MS = 1400;
