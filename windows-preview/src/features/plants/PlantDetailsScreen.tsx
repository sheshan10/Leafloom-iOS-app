import { BookOpen, ChevronDown, Droplets, Leaf, MapPin, Pencil, Plus, Sprout, Sun, Tag, Trash2, Waves, Wind } from 'lucide-react';
import { useMemo, useState, type ReactNode } from 'react';
import { useRouter } from '../../app/router';
import { DangerButton, IconButton, SecondaryButton } from '../../components/Button';
import { CareTaskRow } from '../../components/CareTaskRow';
import { ConfirmDialog } from '../../components/ConfirmDialog';
import { CategoryIcon } from '../../components/Icons';
import { Card, PushedScreen, SectionHeader } from '../../components/Layout';
import { FavoriteButton } from '../../components/PlantCard';
import { PlantThumbnail } from '../../components/PlantThumbnail';
import { Badge, SampleBadge } from '../../components/StatusBadge';
import { ErrorState } from '../../components/States';
import { useToast } from '../../components/Toast';
import { categoryLabel, humidityOptions, identificationStatusOptions, labelFor, sunlightOptions } from '../../data/catalog';
import { useData } from '../../data/store';
import { formatDate } from '../../utils/dates';
import { sortByDueDate } from '../../utils/recurrence';
import { useTaskCompletion } from '../care/useTaskCompletion';

function Collapsible({ title, count, children, defaultOpen = false }: { title: string; count?: number; children: ReactNode; defaultOpen?: boolean }) {
  const [open, setOpen] = useState(defaultOpen);
  return (
    <section className={`collapsible ${open ? 'is-open' : ''}`}>
      <button type="button" className="collapsible__header" aria-expanded={open} onClick={() => setOpen((o) => !o)}>
        <span className="t-title3">{title}</span>
        {count !== undefined && <span className="collapsible__count">{count}</span>}
        <ChevronDown size={18} aria-hidden className="collapsible__chevron" />
      </button>
      {open && <div className="collapsible__body">{children}</div>}
    </section>
  );
}

function CareFact({ icon, label, value }: { icon: ReactNode; label: string; value?: string }) {
  return (
    <div className="care-fact">
      <span className="care-fact__icon" aria-hidden>
        {icon}
      </span>
      <span className="care-fact__label">{label}</span>
      <span className="care-fact__value">{value ?? 'Not set'}</span>
    </div>
  );
}

export function PlantDetailsScreen({ plantId }: { plantId: string }) {
  const { plants, tasks, journal, actions } = useData();
  const router = useRouter();
  const toast = useToast();
  const toggleTask = useTaskCompletion();
  const [confirmDelete, setConfirmDelete] = useState(false);
  const plant = plants.find((p) => p.id === plantId);

  const plantTasks = useMemo(() => tasks.filter((t) => t.plantId === plantId), [tasks, plantId]);
  const openTasks = useMemo(() => plantTasks.filter((t) => !t.isCompleted).sort(sortByDueDate), [plantTasks]);
  const history = useMemo(
    () => plantTasks.filter((t) => t.isCompleted).sort((a, b) => (b.completedAt ?? '').localeCompare(a.completedAt ?? '')),
    [plantTasks],
  );
  const entries = useMemo(() => journal.filter((j) => j.plantId === plantId).sort((a, b) => b.entryDate.localeCompare(a.entryDate)), [journal, plantId]);

  if (!plant) {
    return (
      <PushedScreen title="Plant">
        <ErrorState title="Plant not found" message="This plant may have been deleted." />
      </PushedScreen>
    );
  }

  const onDelete = async () => {
    setConfirmDelete(false);
    router.pop();
    try {
      await actions.deletePlant(plant.id);
      toast(`${plant.name} was deleted.`, { kind: 'success' });
    } catch (e) {
      toast(e instanceof Error ? e.message : 'Could not delete the plant.', { kind: 'error' });
    }
  };

  const hero = (
    <div className="hero">
      <PlantThumbnail plant={plant} decorative={false} className="hero__image" />
      <div className="hero__scrim" />
      <div className="hero__text">
        <div className="hero__badges">
          {plant.isSample && <SampleBadge />}
        </div>
        <h1 className="t-large-title hero__title">{plant.name}</h1>
        {plant.scientificName && <p className="hero__scientific">{plant.scientificName}</p>}
      </div>
      <FavoriteButton plant={plant} onToggle={() => void actions.toggleFavorite(plant.id)} onImage />
    </div>
  );

  return (
    <PushedScreen title={plant.name} hero={hero} trailing={<IconButton icon={Pencil} label={`Edit ${plant.name}`} tone="onImage" onClick={() => router.openSheet({ name: 'editPlant', plantId: plant.id })} />}>
      <div className="badge-row">
        <Badge tone="neutral">
          <CategoryIcon category={plant.category} size={13} /> {categoryLabel(plant.category)}
        </Badge>
        <Badge tone={plant.identificationStatus === 'identified' ? 'success' : plant.identificationStatus === 'suggested' ? 'amber' : 'neutral'} icon={Leaf}>
          {labelFor(identificationStatusOptions, plant.identificationStatus)}
        </Badge>
        {plant.location && (
          <Badge tone="neutral" icon={MapPin}>
            {plant.location}
          </Badge>
        )}
      </div>
      {plant.commonName && <p className="t-subhead t-secondary details-common">Also known as {plant.commonName}</p>}

      <section aria-labelledby="next-care">
        <SectionHeader
          title="Next care"
          id="next-care"
          action={
            <button type="button" className="text-btn" onClick={() => router.openSheet({ name: 'addTask', plantId: plant.id })}>
              <Plus size={16} aria-hidden /> Add task
            </button>
          }
        />
        {openTasks.length === 0 ? (
          <div className="inline-empty">No care scheduled for {plant.name}.</div>
        ) : (
          <div className="list-card">
            {openTasks.slice(0, 3).map((t) => (
              <CareTaskRow key={t.id} task={t} onOpen={() => router.push({ name: 'taskDetails', taskId: t.id })} onToggleComplete={() => void toggleTask(t)} />
            ))}
          </div>
        )}
      </section>

      <section aria-labelledby="care-profile">
        <SectionHeader title="Care profile" id="care-profile" />
        <Card className="care-facts">
          <CareFact icon={<Droplets size={18} />} label="Watering" value={plant.wateringIntervalDays ? `Every ${plant.wateringIntervalDays} days` : undefined} />
          <CareFact icon={<Sprout size={18} />} label="Fertilising" value={plant.fertilizingIntervalDays ? `Every ${plant.fertilizingIntervalDays} days` : undefined} />
          <CareFact icon={<Sun size={18} />} label="Light" value={labelFor(sunlightOptions, plant.sunlightPreference)} />
          <CareFact icon={<Wind size={18} />} label="Humidity" value={labelFor(humidityOptions, plant.humidityPreference)} />
          <CareFact icon={<Waves size={18} />} label="Soil" value={plant.soilPreference} />
          <CareFact icon={<Leaf size={18} />} label="Added" value={formatDate(plant.dateAdded, { day: 'numeric', month: 'short', year: 'numeric' })} />
        </Card>
      </section>

      <section aria-labelledby="journal-heading">
        <SectionHeader
          title="Growth journal"
          id="journal-heading"
          action={
            <button type="button" className="text-btn" aria-label="Open journal" onClick={() => router.push({ name: 'journal', plantId: plant.id })}>
              <BookOpen size={16} aria-hidden /> Open
            </button>
          }
        />
        {entries.length === 0 ? (
          <div className="inline-empty">
            No entries yet.{' '}
            <button type="button" className="text-btn" onClick={() => router.openSheet({ name: 'addJournal', plantId: plant.id })}>
              Add the first one
            </button>
          </div>
        ) : (
          <ol className="timeline timeline--compact">
            {entries.slice(0, 3).map((e) => (
              <li key={e.id} className="timeline__item">
                <span className="timeline__dot" aria-hidden />
                <div className="timeline__content">
                  <p className="t-footnote t-secondary">
                    {formatDate(e.entryDate, { day: 'numeric', month: 'short', year: 'numeric' })}
                    {e.heightCm ? ` · ${e.heightCm} cm` : ''}
                  </p>
                  <p className="t-subhead">{e.notes}</p>
                </div>
                {e.imageRef && <img src={e.imageRef} alt="" className="timeline__thumb" loading="lazy" />}
              </li>
            ))}
          </ol>
        )}
      </section>

      {plant.notes && (
        <section aria-labelledby="notes-heading">
          <SectionHeader title="Notes" id="notes-heading" />
          <Card>
            <p className="t-body notes-text">{plant.notes}</p>
          </Card>
        </section>
      )}

      {plant.tags.length > 0 && (
        <div className="badge-row" aria-label="Tags">
          {plant.tags.map((t) => (
            <Badge key={t} tone="neutral" icon={Tag}>
              {t}
            </Badge>
          ))}
        </div>
      )}

      <Collapsible title="Care history" count={history.length}>
        {history.length === 0 ? (
          <p className="t-subhead t-secondary">Completed care will appear here.</p>
        ) : (
          <ul className="history-list">
            {history.slice(0, 10).map((t) => (
              <li key={t.id}>
                <span>{t.title}</span>
                <span className="t-footnote t-secondary">{t.completedAt ? formatDate(t.completedAt, { day: 'numeric', month: 'short' }) : ''}</span>
              </li>
            ))}
          </ul>
        )}
      </Collapsible>

      <div className="details-actions">
        <SecondaryButton icon={Pencil} fullWidth onClick={() => router.openSheet({ name: 'editPlant', plantId: plant.id })}>
          Edit plant
        </SecondaryButton>
        <DangerButton icon={Trash2} fullWidth onClick={() => setConfirmDelete(true)}>
          Delete plant
        </DangerButton>
      </div>

      <ConfirmDialog
        open={confirmDelete}
        title={`Delete ${plant.name}?`}
        message={`This also deletes ${plantTasks.length} care task${plantTasks.length === 1 ? '' : 's'} and ${entries.length} journal entr${entries.length === 1 ? 'y' : 'ies'}. Identification history is kept. This cannot be undone.`}
        confirmLabel="Delete plant"
        onConfirm={() => void onDelete()}
        onCancel={() => setConfirmDelete(false)}
      />
    </PushedScreen>
  );
}
