import { useState } from 'react';
import type { Plant } from '../types/models';
import { CategoryIcon } from './Icons';

interface Props {
  plant: Pick<Plant, 'name' | 'imageRef' | 'category'>;
  className?: string;
  /** Decorative when the plant name is already visible next to the image. */
  decorative?: boolean;
}

/** Photo with a designed category placeholder for missing or broken images. */
export function PlantThumbnail({ plant, className = '', decorative = true }: Props) {
  const [failed, setFailed] = useState(false);
  const showImage = plant.imageRef && !failed;
  return (
    <div className={`plant-thumb ${className}`}>
      {showImage ? (
        <img
          src={plant.imageRef}
          alt={decorative ? '' : `Photo of ${plant.name}`}
          loading="lazy"
          decoding="async"
          onError={() => setFailed(true)}
        />
      ) : (
        <div className="plant-thumb__placeholder" role={decorative ? undefined : 'img'} aria-label={decorative ? undefined : `No photo of ${plant.name}`}>
          <CategoryIcon category={plant.category} size={36} />
        </div>
      )}
    </div>
  );
}
