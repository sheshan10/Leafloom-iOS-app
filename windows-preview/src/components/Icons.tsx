import { Droplets, Eye, Flower, Scissors, Shovel, Sparkles, Sprout, type LucideIcon } from 'lucide-react';
import iconData from '../data/categoryIcons.json';
import type { CareCategory, PlantCategory } from '../types/models';

type Shape = { tag: 'path'; d: string } | { tag: 'circle'; cx: number; cy: number; r: number };
const shapes = iconData as unknown as Record<PlantCategory, Shape[]>;

/** Original LeafLoom category glyphs (same stroke grid as Lucide). Also exported to the native asset catalog. */
export function CategoryIcon({ category, size = 20, className }: { category: PlantCategory; size?: number; className?: string }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.75}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden
      className={className}
    >
      {(shapes[category] ?? shapes.foliage).map((s, i) =>
        s.tag === 'path' ? <path key={i} d={s.d} /> : <circle key={i} cx={s.cx} cy={s.cy} r={s.r} />,
      )}
    </svg>
  );
}

export const careIcons: Record<CareCategory, LucideIcon> = {
  watering: Droplets,
  fertilizing: Sprout,
  pruning: Scissors,
  repotting: Shovel,
  cleaning: Sparkles,
  inspection: Eye,
  custom: Flower,
};

export function CareIcon({ category, size = 18 }: { category: CareCategory; size?: number }) {
  const Icon = careIcons[category];
  return (
    <span className={`care-icon care-icon--${category}`} aria-hidden>
      <Icon size={size} />
    </span>
  );
}

export function BrandMark({ size = 32 }: { size?: number }) {
  return <img src="/illustrations/brand-mark.svg" width={size} height={size} alt="" aria-hidden className="brand-mark" />;
}
