import type { Preferences } from '../types/models';
import { routeTitles, sheetTitles, tabTitles, type Route, type Sheet, type Tab } from './router';

export interface ScreenInfo {
  name: string;
  description: string;
  native: string;
}

const tabInfo: Record<Tab, Omit<ScreenInfo, 'name'>> = {
  home: { description: 'Personal dashboard: greeting, plants that need attention, today’s and upcoming care, weekly progress ring and recently added plants. Every number is calculated from stored records.', native: 'Features/Dashboard/DashboardView.swift' },
  plants: { description: 'The plant collection with search (name, common and scientific name, tags), category/location/favourite filters, three sort orders and grid/list layouts.', native: 'Features/PlantCollection/PlantCollectionView.swift' },
  identify: { description: 'Choose a photo to identify. In this preview results are SIMULATED. The native app runs a Core ML image classifier via Vision when a compatible model is bundled.', native: 'Features/PlantIdentification/IdentifyView.swift' },
  care: { description: 'Care task list filtered by upcoming, overdue and completed. Completing a recurring task keeps it in history and schedules the next occurrence.', native: 'Features/CareTasks/CareTaskListView.swift' },
  insights: { description: 'Charts and statistics computed from stored plants and tasks: categories, additions over time, completion trend. Native version uses Swift Charts.', native: 'Features/Insights/InsightsView.swift' },
};

const routeInfo: Record<Route['name'], Omit<ScreenInfo, 'name'>> = {
  plantDetails: { description: 'Hero photo, identification status, care profile, next care, recent care history, growth journal timeline, notes, and edit/delete actions.', native: 'Features/PlantDetails/PlantDetailView.swift' },
  taskDetails: { description: 'A single care task with status, recurrence rule, linked plant and the full history of its recurring series. Complete, undo, edit or delete.', native: 'Features/CareTasks/CareTaskDetailView.swift' },
  journal: { description: 'Chronological growth journal for one plant, with optional photos, height measurements and a before/after comparison when two photos exist.', native: 'Features/GrowthJournal/GrowthJournalView.swift' },
  identifyResult: { description: 'Identification results: suggested label, alternatives, confidence only when a real model supplies it, general care info and Save to My Plants.', native: 'Features/PlantIdentification/IdentificationResultView.swift' },
  settings: { description: 'Appearance, collection layout, reminders, onboarding replay, privacy information, version, and data reset with confirmation.', native: 'Features/Settings/SettingsView.swift' },
  reminderSettings: { description: 'Reminder preferences. The native app uses UserNotifications; this preview only simulates permission and reminders in-app.', native: 'Features/Settings/ReminderSettingsView.swift' },
  about: { description: 'About LeafLoom: purpose, technologies, privacy statement and asset credits.', native: 'Features/Settings/AboutView.swift' },
};

const sheetInfo: Record<Sheet['name'], string> = {
  addPlant: 'Create a plant with validation. Only name and category are required.',
  editPlant: 'Edit every plant field. The record id is preserved and all screens update on save.',
  addTask: 'Create a care task, optionally linked to a plant and recurring every N days.',
  editTask: 'Edit a care task. In the native app the pending notification is rescheduled.',
  addJournal: 'Add a dated observation with an optional photo and height.',
  editJournal: 'Edit or delete a journal entry.',
};

export function describeScreen(prefs: Preferences, tab: Tab, current?: Route, sheet?: Sheet): ScreenInfo {
  if (!prefs.onboardingComplete) {
    return { name: 'Onboarding', description: 'Welcome flow introducing collection management, AI-assisted identification and reminders. Completion is persisted.', native: 'Features/Onboarding/OnboardingView.swift' };
  }
  if (sheet) {
    return { name: `${sheetTitles[sheet.name]} (sheet)`, description: sheetInfo[sheet.name], native: sheet.name.includes('Plant') ? 'Features/PlantCollection/PlantFormView.swift' : sheet.name.includes('Task') ? 'Features/CareTasks/CareTaskFormView.swift' : 'Features/GrowthJournal/JournalEntryFormView.swift' };
  }
  if (current) return { name: routeTitles[current.name], ...routeInfo[current.name] };
  return { name: tabTitles[tab], ...tabInfo[tab] };
}
