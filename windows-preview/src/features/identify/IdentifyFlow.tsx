import { createContext, useCallback, useContext, useMemo, useRef, useState, type ReactNode } from 'react';
import { simulateIdentification, SIMULATED_DELAY_MS, type SimulatedResult } from './simulatedIdentifier';

export type IdentifyStatus = 'idle' | 'ready' | 'processing' | 'result' | 'error';

interface IdentifyFlowValue {
  image?: string;
  status: IdentifyStatus;
  result?: SimulatedResult;
  error?: string;
  savedRecordId?: string;
  selectImage(image: string): void;
  setError(message: string): void;
  analyse(): Promise<SimulatedResult | undefined>;
  cancel(): void;
  clear(): void;
  markSaved(id: string): void;
}

const Ctx = createContext<IdentifyFlowValue | null>(null);

/** Holds the identification session so it survives pushing the results screen and switching tabs. */
export function IdentifyFlowProvider({ children, delayMs = SIMULATED_DELAY_MS }: { children: ReactNode; delayMs?: number }) {
  const [image, setImage] = useState<string>();
  const [status, setStatus] = useState<IdentifyStatus>('idle');
  const [result, setResult] = useState<SimulatedResult>();
  const [error, setErrorState] = useState<string>();
  const [savedRecordId, setSavedRecordId] = useState<string>();
  const run = useRef(0);

  const selectImage = useCallback((img: string) => {
    run.current++;
    setImage(img);
    setResult(undefined);
    setErrorState(undefined);
    setSavedRecordId(undefined);
    setStatus('ready');
  }, []);

  const analyse = useCallback(async () => {
    if (!image) return undefined;
    const token = ++run.current;
    setStatus('processing');
    await new Promise((r) => setTimeout(r, delayMs));
    if (token !== run.current) return undefined; // cancelled or replaced
    const r = simulateIdentification(image);
    setResult(r);
    setStatus('result');
    return r;
  }, [image, delayMs]);

  const value = useMemo<IdentifyFlowValue>(
    () => ({
      image,
      status,
      result,
      error,
      savedRecordId,
      selectImage,
      setError: (m) => {
        setErrorState(m);
        setStatus('error');
      },
      analyse,
      cancel: () => {
        run.current++;
        setStatus(image ? 'ready' : 'idle');
      },
      clear: () => {
        run.current++;
        setImage(undefined);
        setResult(undefined);
        setErrorState(undefined);
        setSavedRecordId(undefined);
        setStatus('idle');
      },
      markSaved: setSavedRecordId,
    }),
    [image, status, result, error, savedRecordId, selectImage, analyse],
  );
  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useIdentifyFlow() {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error('useIdentifyFlow must be used inside <IdentifyFlowProvider>');
  return ctx;
}
