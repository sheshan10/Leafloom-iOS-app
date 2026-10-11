import type {
  CareCategory,
  HumidityPreference,
  IdentificationStatus,
  PlantCategory,
  SunlightPreference,
} from '../types/models';

export const plantCategories: { id: PlantCategory; label: string }[] = [
  { id: 'foliage', label: 'Foliage' },
  { id: 'succulent', label: 'Succulents & Cacti' },
  { id: 'flowering', label: 'Flowering' },
  { id: 'herb', label: 'Herbs' },
  { id: 'tree', label: 'Trees & Shrubs' },
  { id: 'fern', label: 'Ferns' },
  { id: 'trailing', label: 'Trailing & Climbing' },
  { id: 'edible', label: 'Fruit & Vegetables' },
];

export const categoryLabel = (id: PlantCategory) =>
  plantCategories.find((c) => c.id === id)?.label ?? id;

export const careCategories: { id: CareCategory; label: string; verb: string }[] = [
  { id: 'watering', label: 'Watering', verb: 'Water' },
  { id: 'fertilizing', label: 'Fertilising', verb: 'Fertilise' },
  { id: 'pruning', label: 'Pruning', verb: 'Prune' },
  { id: 'repotting', label: 'Repotting', verb: 'Repot' },
  { id: 'cleaning', label: 'Cleaning leaves', verb: 'Clean leaves of' },
  { id: 'inspection', label: 'Inspection', verb: 'Inspect' },
  { id: 'custom', label: 'Custom', verb: 'Care for' },
];

export const careCategoryLabel = (id: CareCategory) =>
  careCategories.find((c) => c.id === id)?.label ?? id;

export const sunlightOptions: { id: SunlightPreference; label: string }[] = [
  { id: 'low', label: 'Low light' },
  { id: 'medium', label: 'Medium light' },
  { id: 'bright-indirect', label: 'Bright, indirect' },
  { id: 'full-sun', label: 'Full sun' },
];

export const humidityOptions: { id: HumidityPreference; label: string }[] = [
  { id: 'low', label: 'Low' },
  { id: 'average', label: 'Average' },
  { id: 'high', label: 'High' },
];

export const identificationStatusOptions: { id: IdentificationStatus; label: string }[] = [
  { id: 'identified', label: 'Identified' },
  { id: 'suggested', label: 'Suggested by Identify' },
  { id: 'unknown', label: 'Not yet identified' },
];

export const labelFor = <T extends string>(options: { id: T; label: string }[], id?: T) =>
  id ? (options.find((o) => o.id === id)?.label ?? id) : undefined;
