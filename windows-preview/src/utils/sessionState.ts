import { useCallback, useState } from 'react';

const memory = new Map<string, unknown>();

/**
 * useState that survives the component unmounting while the app is open (e.g. pushing a detail screen
 * and coming back), similar to a SwiftUI view model owned by the tab's NavigationStack.
 */
export function useSessionState<T>(key: string, initial: T) {
  const [value, setValue] = useState<T>(() => (memory.has(key) ? (memory.get(key) as T) : initial));
  const set = useCallback(
    (next: T | ((prev: T) => T)) => {
      setValue((prev) => {
        const resolved = typeof next === 'function' ? (next as (p: T) => T)(prev) : next;
        memory.set(key, resolved);
        return resolved;
      });
    },
    [key],
  );
  return [value, set] as const;
}

export const clearSessionState = () => memory.clear();
