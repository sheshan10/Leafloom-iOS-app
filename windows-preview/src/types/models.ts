// Mirrors the native Core Data model (native-ios/LeafLoom/Data/LeafLoom.xcdatamodeld).
// Dates are ISO-8601 strings so records survive IndexedDB structured cloning unchanged.

export type PlantCategory =
  | 'foliage'
  | 'succulent'
  | 'flowering'
  | 'herb'
  | 'tree'
  | 'fern'
  | 'trailing'
  | 'edible';

export type IdentificationStatus = 'identified' | 'suggested' | 'unknown';

export type SunlightPreference = 'low' | 'medium' | 'bright-indirect' | 'full-sun';
export type HumidityPreference = 'low' | 'average' | 'high';

export interface Plant {
  id: string;
  name: string;
  commonName?: string;
  scientificName?: string;
  category: PlantCategory;
  identificationStatus: IdentificationStatus;
  /** Either a bundled sample path ("/images/plants/x.jpg") or a data: URL for user photos. */
  imageRef?: string;
  location?: string;
  acquisitionDate?: string;
  dateAdded: string;
  wateringIntervalDays?: number;
  fertilizingIntervalDays?: number;
  sunlightPreference?: SunlightPreference;
  humidityPreference?: HumidityPreference;
  soilPreference?: string;
  notes?: string;
  tags: string[];
  isFavorite: boolean;
  isSample: boolean;
  createdAt: string;
  updatedAt: string;
}

export type CareCategory =
  | 'watering'
  | 'fertilizing'
  | 'pruning'
  | 'repotting'
  | 'cleaning'
  | 'inspection'
  | 'custom';

export interface CareTask {
  id: string;
  /** Shared by every occurrence of a recurring task. */
  seriesId: string;
  plantId?: string;
  title: string;
  descriptionText?: string;
  category: CareCategory;
  dueDate: string;
  isCompleted: boolean;
  completedAt?: string;
  recurrenceIntervalDays?: number;
  notes?: string;
  /** Id of the next occurrence created when this task was completed (used by undo). */
  spawnedTaskId?: string;
  isSample: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface JournalEntry {
  id: string;
  plantId: string;
  entryDate: string;
  notes: string;
  imageRef?: string;
  heightCm?: number;
  createdAt: string;
  updatedAt: string;
}

export interface IdentificationRecord {
  id: string;
  dateCreated: string;
  imageRef?: string;
  predictedLabel: string;
  /** Only present when supplied by a real model. Never set for simulated results. */
  confidence?: number;
  modelIdentifier: string;
  isDemoResult: boolean;
  plantId?: string;
}

export type ThemePreference = 'system' | 'light' | 'dark';
export type CollectionLayout = 'grid' | 'list';

export interface Preferences {
  theme: ThemePreference;
  collectionLayout: CollectionLayout;
  remindersEnabled: boolean;
  reminderHour: number;
  onboardingComplete: boolean;
  sampleDataSeeded: boolean;
  /** Simulated permission state — the browser preview never uses real notifications. */
  notificationPermission: 'notDetermined' | 'granted' | 'denied';
}

export const defaultPreferences: Preferences = {
  theme: 'system',
  collectionLayout: 'grid',
  remindersEnabled: true,
  reminderHour: 9,
  onboardingComplete: false,
  sampleDataSeeded: false,
  notificationPermission: 'notDetermined',
};

export type PlantDraft = Omit<Plant, 'id' | 'createdAt' | 'updatedAt' | 'isSample' | 'dateAdded'> & {
  dateAdded?: string;
};

export type CareTaskDraft = Pick<
  CareTask,
  'plantId' | 'title' | 'descriptionText' | 'category' | 'dueDate' | 'recurrenceIntervalDays' | 'notes'
>;

export type JournalDraft = Pick<JournalEntry, 'plantId' | 'entryDate' | 'notes' | 'imageRef' | 'heightCm'>;
