import type { CareCategory, CareTask, JournalEntry, Plant } from '../types/models';
import { addDays, startOfDay } from '../utils/dates';
import type { SeedData } from './repository';

/**
 * Demonstration records shown on first launch. Every record has isSample = true so it can be
 * labelled in the UI and removed with "Reset" or "Erase all data". Values are relative to `now`
 * so the dashboard always has something due today, something overdue and some history.
 */
interface SamplePlantSpec {
  key: string;
  name: string;
  commonName: string;
  scientificName: string;
  category: Plant['category'];
  location: string;
  image: string;
  addedDaysAgo: number;
  water: number;
  fertilise?: number;
  /** Days from today until the open watering task is due (negative = overdue). */
  nextWaterOffset: number;
  sunlight: Plant['sunlightPreference'];
  humidity: Plant['humidityPreference'];
  soil: string;
  favorite?: boolean;
  tags: string[];
  notes?: string;
}

const specs: SamplePlantSpec[] = [
  { key: 'monstera', name: 'Monty', commonName: 'Swiss cheese plant', scientificName: 'Monstera deliciosa', category: 'foliage', location: 'Living room', image: 'monstera.jpg', addedDaysAgo: 150, water: 7, fertilise: 30, nextWaterOffset: 0, sunlight: 'bright-indirect', humidity: 'average', soil: 'Chunky aroid mix', favorite: true, tags: ['statement', 'fast-growing'], notes: 'New leaf unfurling near the moss pole.' },
  { key: 'snake', name: 'Sunny', commonName: 'Snake plant', scientificName: 'Dracaena trifasciata', category: 'succulent', location: 'Bedroom', image: 'snake-plant.jpg', addedDaysAgo: 120, water: 14, nextWaterOffset: 3, sunlight: 'low', humidity: 'low', soil: 'Cactus mix', tags: ['low-maintenance'] },
  { key: 'pothos', name: 'Goldie', commonName: 'Golden pothos', scientificName: 'Epipremnum aureum', category: 'trailing', location: 'Office', image: 'pothos.jpg', addedDaysAgo: 95, water: 7, fertilise: 30, nextWaterOffset: -2, sunlight: 'medium', humidity: 'average', soil: 'Potting mix + perlite', favorite: true, tags: ['trailing', 'propagated'] },
  { key: 'fiddle', name: 'Figgy', commonName: 'Fiddle leaf fig', scientificName: 'Ficus lyrata', category: 'tree', location: 'Living room', image: 'fiddle-leaf-fig.jpg', addedDaysAgo: 70, water: 8, fertilise: 30, nextWaterOffset: 1, sunlight: 'bright-indirect', humidity: 'average', soil: 'Indoor plant mix', tags: ['tall'] },
  { key: 'lily', name: 'Lily', commonName: 'Peace lily', scientificName: 'Spathiphyllum wallisii', category: 'flowering', location: 'Bathroom', image: 'peace-lily.jpg', addedDaysAgo: 48, water: 5, nextWaterOffset: -1, sunlight: 'medium', humidity: 'high', soil: 'Moisture-retentive mix', tags: ['flowering'] },
  { key: 'aloe', name: 'Aloe', commonName: 'Aloe vera', scientificName: 'Aloe vera', category: 'succulent', location: 'Kitchen window', image: 'aloe-vera.jpg', addedDaysAgo: 30, water: 14, nextWaterOffset: 6, sunlight: 'full-sun', humidity: 'low', soil: 'Gritty succulent mix', tags: ['sun-lover'] },
  { key: 'basil', name: 'Basil', commonName: 'Sweet basil', scientificName: 'Ocimum basilicum', category: 'herb', location: 'Kitchen window', image: 'basil.jpg', addedDaysAgo: 12, water: 2, fertilise: 21, nextWaterOffset: 0, sunlight: 'full-sun', humidity: 'average', soil: 'Rich herb compost', favorite: true, tags: ['edible', 'kitchen'] },
  { key: 'calathea', name: 'Orbi', commonName: 'Calathea orbifolia', scientificName: 'Goeppertia orbifolia', category: 'foliage', location: 'Office', image: 'calathea.jpg', addedDaysAgo: 4, water: 5, nextWaterOffset: 2, sunlight: 'medium', humidity: 'high', soil: 'Airy moisture-retentive mix', tags: ['humidity-lover'] },
];

const at = (base: Date, days: number, hour = 9) => {
  const d = addDays(startOfDay(base), days);
  d.setHours(hour, 0, 0, 0);
  return d;
};

const careTitle = (category: CareCategory, plantName: string) => {
  switch (category) {
    case 'watering':
      return `Water ${plantName}`;
    case 'fertilizing':
      return `Fertilise ${plantName}`;
    default:
      return `Care for ${plantName}`;
  }
};

/** A recurring series: past completed occurrences (history) plus one open occurrence. */
const buildSeries = (
  plant: Plant,
  category: CareCategory,
  interval: number,
  nextOffset: number,
  now: Date,
  historyDays = 56,
): CareTask[] => {
  const seriesId = `sample-${plant.id}-${category}`;
  const occurrences: CareTask[] = [];
  let k = 0;
  for (let offset = nextOffset; offset >= -historyDays; offset -= interval, k++) {
    const due = at(now, offset);
    const isOpen = k === 0;
    // Occasionally completed a day late so the history looks realistic.
    const completed = isOpen ? undefined : addDays(due, k % 3 === 0 ? 1 : 0);
    occurrences.push({
      id: `${seriesId}-${k}`,
      seriesId,
      plantId: plant.id,
      title: careTitle(category, plant.name),
      descriptionText: category === 'watering' ? 'Water until it drains from the pot, then empty the saucer.' : 'Use a balanced liquid fertiliser at half strength.',
      category,
      dueDate: due.toISOString(),
      isCompleted: !isOpen,
      completedAt: completed?.toISOString(),
      recurrenceIntervalDays: interval,
      isSample: true,
      createdAt: (completed ?? now).toISOString(),
      updatedAt: (completed ?? now).toISOString(),
    });
  }
  // Link each completed occurrence to the one created after it (newer = lower k).
  for (let i = 1; i < occurrences.length; i++) occurrences[i].spawnedTaskId = occurrences[i - 1].id;
  return occurrences;
};

export const buildSampleData = (now = new Date()): SeedData => {
  const plants: Plant[] = specs.map((s) => {
    const added = at(now, -s.addedDaysAgo, 11).toISOString();
    return {
      id: `sample-${s.key}`,
      name: s.name,
      commonName: s.commonName,
      scientificName: s.scientificName,
      category: s.category,
      identificationStatus: 'identified',
      imageRef: `/images/plants/${s.image}`,
      location: s.location,
      acquisitionDate: at(now, -s.addedDaysAgo - 7).toISOString(),
      dateAdded: added,
      wateringIntervalDays: s.water,
      fertilizingIntervalDays: s.fertilise,
      sunlightPreference: s.sunlight,
      humidityPreference: s.humidity,
      soilPreference: s.soil,
      notes: s.notes,
      tags: s.tags,
      isFavorite: !!s.favorite,
      isSample: true,
      createdAt: added,
      updatedAt: added,
    };
  });

  const tasks: CareTask[] = [];
  plants.forEach((plant, i) => {
    const spec = specs[i];
    const history = Math.min(56, spec.addedDaysAgo);
    tasks.push(...buildSeries(plant, 'watering', spec.water, spec.nextWaterOffset, now, history));
    if (spec.fertilise) tasks.push(...buildSeries(plant, 'fertilizing', spec.fertilise, spec.nextWaterOffset + 4, now, history));
  });
  tasks.push({
    id: 'sample-inspection-0',
    seriesId: 'sample-inspection',
    title: 'Check all plants for pests',
    descriptionText: 'Look under leaves and along stems for webbing, sticky residue or spots.',
    category: 'inspection',
    dueDate: at(now, 4).toISOString(),
    isCompleted: false,
    recurrenceIntervalDays: 14,
    isSample: true,
    createdAt: now.toISOString(),
    updatedAt: now.toISOString(),
  });
  tasks.push({
    id: 'sample-repot-0',
    seriesId: 'sample-repot',
    plantId: 'sample-fiddle',
    title: 'Repot Figgy into a larger pot',
    descriptionText: 'Roots are circling the base. Move up one pot size in spring.',
    category: 'repotting',
    dueDate: at(now, 12).toISOString(),
    isCompleted: false,
    isSample: true,
    createdAt: now.toISOString(),
    updatedAt: now.toISOString(),
  });

  const journal: JournalEntry[] = [
    { id: 'sample-j1', plantId: 'sample-monstera', entryDate: at(now, -140).toISOString(), notes: 'Brought Monty home. Four leaves, one with first splits.', heightCm: 48, createdAt: now.toISOString(), updatedAt: now.toISOString() },
    { id: 'sample-j2', plantId: 'sample-monstera', entryDate: at(now, -60).toISOString(), notes: 'Added a moss pole. Two new leaves this month.', heightCm: 61, createdAt: now.toISOString(), updatedAt: now.toISOString() },
    { id: 'sample-j3', plantId: 'sample-monstera', entryDate: at(now, -3).toISOString(), notes: 'Biggest leaf so far, with seven splits.', heightCm: 74, imageRef: '/images/plants/monstera.jpg', createdAt: now.toISOString(), updatedAt: now.toISOString() },
    { id: 'sample-j4', plantId: 'sample-pothos', entryDate: at(now, -20).toISOString(), notes: 'Took three cuttings to propagate in water.', imageRef: '/images/plants/pothos.jpg', createdAt: now.toISOString(), updatedAt: now.toISOString() },
  ];

  return { plants, tasks, journal };
};
