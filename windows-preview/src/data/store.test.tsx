import { act, renderHook, waitFor } from '@testing-library/react';
import type { ReactNode } from 'react';
import { NOW } from '../test/fixtures';
import { DataProvider, useData } from './store';

let n = 0;
const setup = () => {
  const dbName = `store-test-${++n}`;
  const clock = () => NOW;
  const wrapper = ({ children }: { children: ReactNode }) => (
    <DataProvider dbName={dbName} now={clock}>
      {children}
    </DataProvider>
  );
  return { dbName, clock, ...renderHook(() => useData(), { wrapper }) };
};

describe('DataProvider', () => {
  it('seeds sample data exactly once', async () => {
    const { result, dbName, clock, unmount } = setup();
    await waitFor(() => expect(result.current.status).toBe('ready'));
    const count = result.current.plants.length;
    expect(count).toBe(8);
    unmount();

    const wrapper = ({ children }: { children: ReactNode }) => (
      <DataProvider dbName={dbName} now={clock}>
        {children}
      </DataProvider>
    );
    const second = renderHook(() => useData(), { wrapper });
    await waitFor(() => expect(second.result.current.status).toBe('ready'));
    expect(second.result.current.plants.length).toBe(count);
  });

  it('adds a plant with a generated care schedule', async () => {
    const { result } = setup();
    await waitFor(() => expect(result.current.status).toBe('ready'));
    const before = result.current.tasks.length;
    await act(async () => {
      await result.current.actions.addPlant(
        { name: '  Fern  ', category: 'fern', identificationStatus: 'unknown', tags: [], isFavorite: false, wateringIntervalDays: 4, fertilizingIntervalDays: 30 },
        { createCareSchedule: true, reminderHour: 8 },
      );
    });
    const fern = result.current.plants.find((p) => p.name === 'Fern');
    expect(fern).toBeDefined();
    const schedule = result.current.tasks.filter((t) => t.plantId === fern!.id);
    expect(result.current.tasks.length).toBe(before + 2);
    expect(schedule.map((t) => t.recurrenceIntervalDays).sort()).toEqual([30, 4]);
    expect(new Date(schedule.find((t) => t.category === 'watering')!.dueDate).getHours()).toBe(8);
  });

  it('completes a recurring task, then undo removes the spawned occurrence', async () => {
    const { result } = setup();
    await waitFor(() => expect(result.current.status).toBe('ready'));
    const task = result.current.tasks.find((t) => !t.isCompleted && t.recurrenceIntervalDays)!;
    const before = result.current.tasks.length;

    await act(async () => {
      await result.current.actions.completeTask(task.id);
    });
    expect(result.current.tasks.length).toBe(before + 1);
    expect(result.current.tasks.find((t) => t.id === task.id)?.isCompleted).toBe(true);

    await act(async () => {
      await result.current.actions.undoComplete(task.id);
    });
    expect(result.current.tasks.length).toBe(before);
    expect(result.current.tasks.find((t) => t.id === task.id)?.isCompleted).toBe(false);
  });

  it('deletes a plant together with its tasks and journal entries', async () => {
    const { result } = setup();
    await waitFor(() => expect(result.current.status).toBe('ready'));
    const plant = result.current.plants.find((p) => result.current.journal.some((j) => j.plantId === p.id))!;
    await act(async () => {
      await result.current.actions.deletePlant(plant.id);
    });
    expect(result.current.plants.some((p) => p.id === plant.id)).toBe(false);
    expect(result.current.tasks.some((t) => t.plantId === plant.id)).toBe(false);
    expect(result.current.journal.some((j) => j.plantId === plant.id)).toBe(false);
  });

  it('erases all data and resets to sample data', async () => {
    const { result } = setup();
    await waitFor(() => expect(result.current.status).toBe('ready'));
    await act(async () => {
      await result.current.actions.eraseAllData();
    });
    expect(result.current.plants).toEqual([]);
    await act(async () => {
      await result.current.actions.resetToSampleData();
    });
    expect(result.current.plants).toHaveLength(8);
  });
});
