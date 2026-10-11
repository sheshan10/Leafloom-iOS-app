import raw from './plantKnowledge.json';
import type { HumidityPreference, PlantCategory, SunlightPreference } from '../types/models';

export interface KnowledgeEntry {
  key: string;
  aliases: string[];
  commonName: string;
  scientificName: string;
  category: PlantCategory;
  sunlight: SunlightPreference;
  humidity: HumidityPreference;
  soil: string;
  wateringIntervalDays: number;
  fertilizingIntervalDays: number;
  summary: string;
  image?: string;
}

export const knowledgeDisclaimer: string = raw.disclaimer;
export const knowledgeBase = raw.entries as KnowledgeEntry[];

const norm = (s: string) => s.toLowerCase().replace(/[_-]+/g, ' ').replace(/\s+/g, ' ').trim();

/** Maps a classifier label (e.g. "snake_plant", "Sansevieria trifasciata") to a knowledge entry. Mirrors native LabelMapper. */
export const lookupLabel = (label: string): KnowledgeEntry | undefined => {
  const n = norm(label);
  return knowledgeBase.find((e) => norm(e.key) === n || norm(e.commonName) === n || norm(e.scientificName) === n || e.aliases.some((a) => norm(a) === n));
};
