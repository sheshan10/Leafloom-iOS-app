import { Droplets, Glasses, Info, Move, RotateCcw, Sun } from 'lucide-react';
import { useEffect, useMemo, useRef, useState, type PointerEvent } from 'react';
import { sunlightOptions, labelFor } from '../../data/catalog';
import { useData } from '../../data/store';
import type { Plant, SunlightPreference } from '../../types/models';
import { careStatus } from '../../utils/recurrence';

/**
 * 2D simulation of the Part B visionOS prototype (partB-visionos/). A window lists plants, and the
 * "immersive room" lets the user drag plants around a floor plan. Light zones are estimated from
 * distance to the window, matching the native LightZone model. This is a design preview only.
 */
type Position = { x: number; y: number };
const STORAGE_KEY = 'leafloom.spatial.positions';

const lightOrder: SunlightPreference[] = ['low', 'medium', 'bright-indirect', 'full-sun'];

/** x = 0 is the window wall. Mirrors LightZone.estimate(distanceFromWindow:) in the native prototype. */
export const lightAt = (pos: Position): SunlightPreference => {
  if (pos.x < 0.15 && pos.y > 0.25 && pos.y < 0.75) return 'full-sun';
  if (pos.x < 0.4) return 'bright-indirect';
  if (pos.x < 0.7) return 'medium';
  return 'low';
};

export const lightFit = (plant: Plant, pos: Position): 'good' | 'ok' | 'poor' | 'unknown' => {
  if (!plant.sunlightPreference) return 'unknown';
  const diff = Math.abs(lightOrder.indexOf(plant.sunlightPreference) - lightOrder.indexOf(lightAt(pos)));
  return diff === 0 ? 'good' : diff === 1 ? 'ok' : 'poor';
};

const fitLabel = { good: 'Great light match', ok: 'Acceptable light', poor: 'Poor light match', unknown: 'Light preference not set' };

const defaultPositions = (plants: Plant[]) =>
  Object.fromEntries(plants.map((p, i) => [p.id, { x: 0.2 + (i % 4) * 0.2, y: 0.25 + Math.floor(i / 4) * 0.35 }]));

export function SpatialPreview() {
  const { plants, tasks } = useData();
  const roomRef = useRef<HTMLDivElement>(null);
  const [positions, setPositions] = useState<Record<string, Position>>(() => {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEY) ?? '{}');
    } catch {
      return {};
    }
  });
  const [selected, setSelected] = useState<string | undefined>(plants[0]?.id);
  const [dragging, setDragging] = useState<string>();

  const placed = useMemo(() => {
    const defaults = defaultPositions(plants);
    return plants.map((p) => ({ plant: p, pos: positions[p.id] ?? defaults[p.id] }));
  }, [plants, positions]);

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(positions));
  }, [positions]);

  const move = (id: string, e: PointerEvent) => {
    const rect = roomRef.current?.getBoundingClientRect();
    if (!rect) return;
    const x = Math.min(0.95, Math.max(0.05, (e.clientX - rect.left) / rect.width));
    const y = Math.min(0.92, Math.max(0.08, (e.clientY - rect.top) / rect.height));
    setPositions((p) => ({ ...p, [id]: { x, y } }));
  };

  const nudge = (id: string, dx: number, dy: number) => {
    const current = placed.find((p) => p.plant.id === id)?.pos ?? { x: 0.5, y: 0.5 };
    setPositions((p) => ({ ...p, [id]: { x: Math.min(0.95, Math.max(0.05, current.x + dx)), y: Math.min(0.92, Math.max(0.08, current.y + dy)) } }));
  };

  const sel = placed.find((p) => p.plant.id === selected);
  const selTask = sel ? tasks.filter((t) => t.plantId === sel.plant.id && !t.isCompleted).sort((a, b) => a.dueDate.localeCompare(b.dueDate))[0] : undefined;

  return (
    <div className="spatial">
      <div className="spatial__banner" role="note">
        <Glasses size={18} aria-hidden />
        <p>
          <strong>Part B · LeafLoom Spatial (visionOS) — 2D simulation.</strong> The real prototype uses a SwiftUI window, a RealityKit volume and an ImmersiveSpace. Drag plants (or use arrow keys) to see how light zones fit each plant.
        </p>
      </div>
      <div className="spatial__scene">
        <section className="glass-window" aria-label="LeafLoom Spatial window">
          <header className="glass-window__header">
            <span className="t-headline">My Plants</span>
            <button type="button" className="glass-btn" onClick={() => setPositions({})} aria-label="Reset room layout">
              <RotateCcw size={14} aria-hidden /> Reset
            </button>
          </header>
          <ul className="glass-list">
            {placed.map(({ plant, pos }) => {
              const fit = lightFit(plant, pos);
              return (
                <li key={plant.id}>
                  <button type="button" className={`glass-list__row ${selected === plant.id ? 'is-selected' : ''}`} onClick={() => setSelected(plant.id)}>
                    {plant.imageRef ? <img src={plant.imageRef} alt="" /> : <span className="glass-list__ph" />}
                    <span>
                      <span className="glass-list__name">{plant.name}</span>
                      <span className={`fit fit--${fit}`}>{fitLabel[fit]}</span>
                    </span>
                  </button>
                </li>
              );
            })}
          </ul>
        </section>

        <section className="room" aria-label="Immersive room floor plan">
          <div className="room__floor" ref={roomRef}>
            <div className="room__window" aria-hidden>
              <span>Window</span>
            </div>
            <div className="room__zones" aria-hidden>
              <span className="zone zone--bright">Bright</span>
              <span className="zone zone--medium">Medium</span>
              <span className="zone zone--low">Low</span>
            </div>
            {placed.map(({ plant, pos }) => (
              <button
                key={plant.id}
                type="button"
                className={`room__plant fit-ring--${lightFit(plant, pos)} ${selected === plant.id ? 'is-selected' : ''} ${dragging === plant.id ? 'is-dragging' : ''}`}
                style={{ left: `${pos.x * 100}%`, top: `${pos.y * 100}%` }}
                aria-label={`${plant.name}. ${labelFor(sunlightOptions, lightAt(pos))} here. ${fitLabel[lightFit(plant, pos)]}. Use arrow keys to move.`}
                onPointerDown={(e) => {
                  e.currentTarget.setPointerCapture(e.pointerId);
                  setDragging(plant.id);
                  setSelected(plant.id);
                }}
                onPointerMove={(e) => dragging === plant.id && move(plant.id, e)}
                onPointerUp={() => setDragging(undefined)}
                onKeyDown={(e) => {
                  const step = 0.04;
                  const map: Record<string, [number, number]> = { ArrowLeft: [-step, 0], ArrowRight: [step, 0], ArrowUp: [0, -step], ArrowDown: [0, step] };
                  const d = map[e.key];
                  if (d) {
                    e.preventDefault();
                    nudge(plant.id, d[0], d[1]);
                  }
                }}
              >
                {plant.imageRef ? <img src={plant.imageRef} alt="" draggable={false} /> : <span className="room__plant-ph" />}
                <span className="room__plant-name">{plant.name}</span>
              </button>
            ))}
          </div>
        </section>

        {sel && (
          <aside className="glass-window glass-window--card" aria-label={`${sel.plant.name} care card`}>
            <p className="t-eyebrow">Spatial care card</p>
            <p className="t-title3">{sel.plant.name}</p>
            <p className="glass-fact">
              <Sun size={14} aria-hidden /> Needs {labelFor(sunlightOptions, sel.plant.sunlightPreference) ?? 'unknown'}
            </p>
            <p className="glass-fact">
              <Move size={14} aria-hidden /> Here: {labelFor(sunlightOptions, lightAt(sel.pos))}
            </p>
            <p className={`fit fit--${lightFit(sel.plant, sel.pos)}`}>{fitLabel[lightFit(sel.plant, sel.pos)]}</p>
            {selTask && (
              <p className="glass-fact">
                <Droplets size={14} aria-hidden /> {selTask.title} · {careStatus(selTask) === 'overdue' ? 'overdue' : 'next'}
              </p>
            )}
            <p className="glass-note">
              <Info size={12} aria-hidden /> Light zones are estimated from distance to the window, not measured.
            </p>
          </aside>
        )}
      </div>
    </div>
  );
}
