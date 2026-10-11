import { ChevronRight, Heart, MapPin } from 'lucide-react';
import { memo, useState } from 'react';
import { categoryLabel } from '../data/catalog';
import type { Plant } from '../types/models';
import { relativeDay } from '../utils/dates';
import { PlantThumbnail } from './PlantThumbnail';

interface Props {
  plant: Plant;
  nextCare?: number;
  onOpen(): void;
  onToggleFavorite(): void;
}

function FavoriteButton({ plant, onToggle, onImage }: { plant: Plant; onToggle(): void; onImage?: boolean }) {
  const [bump, setBump] = useState(0);
  return (
    <button
      type="button"
      className={`fav-btn ${onImage ? 'fav-btn--on-image' : ''} ${plant.isFavorite ? 'is-on' : ''}`}
      aria-pressed={plant.isFavorite}
      aria-label={plant.isFavorite ? `Remove ${plant.name} from favourites` : `Add ${plant.name} to favourites`}
      onClick={(e) => {
        e.stopPropagation();
        setBump((b) => b + 1);
        onToggle();
      }}
    >
      <Heart key={bump} size={18} aria-hidden className={bump ? 'pop' : ''} fill={plant.isFavorite ? 'currentColor' : 'none'} />
    </button>
  );
}

const nextCareLabel = (nextCare?: number) => (nextCare === undefined ? 'No care scheduled' : `Next care ${relativeDay(new Date(nextCare).toISOString()).toLowerCase()}`);

export const PlantCard = memo(function PlantCard({ plant, nextCare, onOpen, onToggleFavorite }: Props) {
  return (
    <article className="plant-card">
      <button type="button" className="plant-card__hit" onClick={onOpen} aria-label={`${plant.name}, ${categoryLabel(plant.category)}. ${nextCareLabel(nextCare)}`}>
        <PlantThumbnail plant={plant} className="plant-card__image" />
        <div className="plant-card__body">
          <h3 className="plant-card__name">{plant.name}</h3>
          <p className="plant-card__sub">{plant.commonName ?? categoryLabel(plant.category)}</p>
          <p className="plant-card__meta">{nextCareLabel(nextCare)}</p>
        </div>
      </button>
      <FavoriteButton plant={plant} onToggle={onToggleFavorite} onImage />
    </article>
  );
});

export const PlantRow = memo(function PlantRow({ plant, nextCare, onOpen, onToggleFavorite }: Props) {
  return (
    <article className="plant-row">
      <button type="button" className="plant-row__hit" onClick={onOpen} aria-label={`${plant.name}, ${categoryLabel(plant.category)}. ${nextCareLabel(nextCare)}`}>
        <PlantThumbnail plant={plant} className="plant-row__image" />
        <div className="plant-row__body">
          <h3 className="plant-row__name">{plant.name}</h3>
          <p className="plant-row__sub">
            {plant.scientificName ? <em>{plant.scientificName}</em> : categoryLabel(plant.category)}
          </p>
          <p className="plant-row__meta">
            {plant.location && (
              <>
                <MapPin size={12} aria-hidden /> {plant.location} ·{' '}
              </>
            )}
            {nextCareLabel(nextCare)}
          </p>
        </div>
        <ChevronRight size={18} aria-hidden className="plant-row__chevron" />
      </button>
      <FavoriteButton plant={plant} onToggle={onToggleFavorite} />
    </article>
  );
});

export { FavoriteButton };
