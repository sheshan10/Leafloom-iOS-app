import { createContext, useCallback, useContext, useMemo, useState, type ReactNode } from 'react';
import type { PlantDraft } from '../types/models';

export type Tab = 'home' | 'plants' | 'identify' | 'care' | 'insights';

/** Pushed screens (mirror of the native `Route` enum). */
export type Route =
  | { name: 'plantDetails'; plantId: string }
  | { name: 'taskDetails'; taskId: string }
  | { name: 'journal'; plantId: string }
  | { name: 'identifyResult' }
  | { name: 'settings' }
  | { name: 'reminderSettings' }
  | { name: 'about' };

/** Modal sheets (mirror of the native `SheetRoute` enum). Only one can be open at a time. */
export type Sheet =
  | { name: 'addPlant'; prefill?: Partial<PlantDraft>; identificationId?: string }
  | { name: 'editPlant'; plantId: string }
  | { name: 'addTask'; plantId?: string }
  | { name: 'editTask'; taskId: string }
  | { name: 'addJournal'; plantId?: string }
  | { name: 'editJournal'; entryId: string };

const emptyStacks = (): Record<Tab, Route[]> => ({ home: [], plants: [], identify: [], care: [], insights: [] });

interface RouterValue {
  tab: Tab;
  stack: Route[];
  current?: Route;
  sheet?: Sheet;
  /** Increments on every navigation so screens can reset scroll position. */
  navKey: number;
  selectTab(tab: Tab): void;
  push(route: Route, tab?: Tab): void;
  pop(): void;
  popToRoot(): void;
  openSheet(sheet: Sheet): void;
  closeSheet(): void;
  reset(): void;
}

const RouterContext = createContext<RouterValue | null>(null);

export function RouterProvider({ children, initialTab = 'home' }: { children: ReactNode; initialTab?: Tab }) {
  const [tab, setTab] = useState<Tab>(initialTab);
  const [stacks, setStacks] = useState(emptyStacks);
  const [sheet, setSheet] = useState<Sheet | undefined>();
  const [navKey, setNavKey] = useState(0);
  const bump = () => setNavKey((k) => k + 1);

  const selectTab = useCallback(
    (next: Tab) => {
      // Re-selecting the active tab pops it to its root, like UITabBarController.
      if (next === tab) setStacks((s) => ({ ...s, [next]: [] }));
      setTab(next);
      bump();
    },
    [tab],
  );

  const push = useCallback(
    (route: Route, targetTab?: Tab) => {
      const t = targetTab ?? tab;
      setStacks((s) => ({ ...s, [t]: [...s[t], route] }));
      if (targetTab) setTab(targetTab);
      bump();
    },
    [tab],
  );

  const pop = useCallback(() => {
    setStacks((s) => ({ ...s, [tab]: s[tab].slice(0, -1) }));
    bump();
  }, [tab]);

  const popToRoot = useCallback(() => {
    setStacks((s) => ({ ...s, [tab]: [] }));
    bump();
  }, [tab]);

  const value = useMemo<RouterValue>(
    () => ({
      tab,
      stack: stacks[tab],
      current: stacks[tab].at(-1),
      sheet,
      navKey,
      selectTab,
      push,
      pop,
      popToRoot,
      openSheet: setSheet,
      closeSheet: () => setSheet(undefined),
      reset: () => {
        setStacks(emptyStacks());
        setSheet(undefined);
        setTab('home');
        bump();
      },
    }),
    [tab, stacks, sheet, navKey, selectTab, push, pop, popToRoot],
  );

  return <RouterContext.Provider value={value}>{children}</RouterContext.Provider>;
}

export function useRouter() {
  const ctx = useContext(RouterContext);
  if (!ctx) throw new Error('useRouter must be used inside <RouterProvider>');
  return ctx;
}

export const tabTitles: Record<Tab, string> = {
  home: 'Home',
  plants: 'My Plants',
  identify: 'Identify',
  care: 'Care',
  insights: 'Insights',
};

export const routeTitles: Record<Route['name'], string> = {
  plantDetails: 'Plant details',
  taskDetails: 'Care task details',
  journal: 'Growth journal',
  identifyResult: 'Identification results',
  settings: 'Settings',
  reminderSettings: 'Notifications & reminders',
  about: 'About LeafLoom',
};

export const sheetTitles: Record<Sheet['name'], string> = {
  addPlant: 'Add plant',
  editPlant: 'Edit plant',
  addTask: 'Add care task',
  editTask: 'Edit care task',
  addJournal: 'Add journal entry',
  editJournal: 'Edit journal entry',
};
