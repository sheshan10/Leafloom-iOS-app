import { BatteryFull, Signal, Wifi } from 'lucide-react';
import { useEffect, useLayoutEffect, useRef, useState, type CSSProperties, type ReactNode } from 'react';
import { ToastProvider } from '../components/Toast';
import { DataProvider, useData } from '../data/store';
import { SpatialPreview } from '../features/spatial/SpatialPreview';
import { DevPanel } from './DevPanel';
import { devices, type DeviceId, type DeviceSpec } from './devices';
import { PhoneApp } from './PhoneApp';
import { RouterProvider } from './router';
import { usePrefersReducedMotion, useResolvedTheme } from './theme';

export type PreviewMode = 'iphone' | 'vision';

export function PreviewShell() {
  return (
    <DataProvider>
      <RouterProvider>
        <ShellLayout />
      </RouterProvider>
    </DataProvider>
  );
}

function useIsNarrow() {
  const q = '(max-width: 760px)';
  const [narrow, setNarrow] = useState(() => window.matchMedia?.(q).matches ?? false);
  useEffect(() => {
    const mq = window.matchMedia?.(q);
    if (!mq) return;
    const fn = (e: MediaQueryListEvent) => setNarrow(e.matches);
    mq.addEventListener('change', fn);
    return () => mq.removeEventListener('change', fn);
  }, []);
  return narrow;
}

function ShellLayout() {
  const { preferences } = useData();
  const theme = useResolvedTheme(preferences.theme);
  const systemReduced = usePrefersReducedMotion();
  const [deviceId, setDeviceId] = useState<DeviceId>('iphone-16');
  const [mode, setMode] = useState<PreviewMode>('iphone');
  const [typeScale, setTypeScale] = useState(1);
  const [reducedMotion, setReducedMotion] = useState(false);
  const narrow = useIsNarrow();

  useEffect(() => {
    document.documentElement.dataset.theme = theme;
    document.documentElement.dataset.reducedMotion = String(reducedMotion || systemReduced);
  }, [theme, reducedMotion, systemReduced]);

  return (
    <div className={`shell ${narrow ? 'shell--narrow' : ''}`}>
      <DevPanel
        deviceId={deviceId}
        onDeviceChange={setDeviceId}
        mode={mode}
        onModeChange={setMode}
        typeScale={typeScale}
        onTypeScaleChange={setTypeScale}
        reducedMotion={reducedMotion}
        onReducedMotionChange={setReducedMotion}
        collapsible={narrow}
      />
      <main className="shell__stage" aria-label={mode === 'iphone' ? 'iPhone app preview' : 'visionOS prototype simulation'}>
        {mode === 'iphone' ? (
          <DeviceFrame device={devices[deviceId]} fullBleed={narrow} typeScale={typeScale}>
            <ToastProvider>
              <PhoneApp />
            </ToastProvider>
          </DeviceFrame>
        ) : (
          <SpatialPreview />
        )}
      </main>
    </div>
  );
}

function StatusBar({ device }: { device: DeviceSpec }) {
  const [time, setTime] = useState(() => new Date());
  useEffect(() => {
    const t = window.setInterval(() => setTime(new Date()), 30_000);
    return () => window.clearInterval(t);
  }, []);
  return (
    <div className={`status-bar ${device.island ? 'status-bar--island' : ''}`} aria-hidden>
      <span className="status-bar__time">{time.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' }).replace(/\s?[AP]M/i, '')}</span>
      {device.island && <span className="status-bar__island" />}
      <span className="status-bar__icons">
        <Signal size={15} />
        <Wifi size={15} />
        <BatteryFull size={20} />
      </span>
    </div>
  );
}

/** Scales a realistic iPhone frame to fit the window while keeping logical point sizes. */
function DeviceFrame({ device, fullBleed, typeScale, children }: { device: DeviceSpec; fullBleed: boolean; typeScale: number; children: ReactNode }) {
  const stageRef = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(1);
  const bezel = 14;

  useLayoutEffect(() => {
    if (fullBleed) return;
    const el = stageRef.current;
    if (!el) return;
    const update = () => {
      const availH = el.clientHeight - 32;
      const availW = el.clientWidth - 32;
      setScale(Math.min(1, availH / (device.height + bezel * 2), availW / (device.width + bezel * 2)));
    };
    update();
    const ro = new ResizeObserver(update);
    ro.observe(el);
    return () => ro.disconnect();
  }, [device, fullBleed]);

  const screenStyle = {
    '--safe-top': `${device.safeTop}px`,
    '--safe-bottom': `${device.safeBottom}px`,
    '--type-scale': typeScale,
  } as CSSProperties;

  if (fullBleed) {
    return (
      <div className="phone-screen phone-screen--full" style={{ ...screenStyle, '--safe-top': '12px', '--safe-bottom': '8px' } as CSSProperties}>
        {children}
      </div>
    );
  }

  const outerW = (device.width + bezel * 2) * scale;
  const outerH = (device.height + bezel * 2) * scale;
  return (
    <div className="device-stage" ref={stageRef}>
      <div style={{ width: outerW, height: outerH }}>
        <div
          className="device-frame"
          style={{ width: device.width + bezel * 2, height: device.height + bezel * 2, borderRadius: device.radius + bezel, padding: bezel, transform: `scale(${scale})` }}
          data-device={device.id}
        >
          <div className="phone-screen" style={{ ...screenStyle, width: device.width, height: device.height, borderRadius: device.radius }}>
            <StatusBar device={device} />
            {children}
            {device.safeBottom > 0 && <span className="home-indicator" aria-hidden />}
          </div>
        </div>
      </div>
    </div>
  );
}
