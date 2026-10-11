import { Pencil, Plus, Ruler } from 'lucide-react';
import { useMemo, useState } from 'react';
import { useRouter } from '../../app/router';
import { IconButton, PrimaryButton } from '../../components/Button';
import { Card, PushedScreen, SectionHeader } from '../../components/Layout';
import { EmptyState, ErrorState } from '../../components/States';
import { useData } from '../../data/store';
import { formatDate } from '../../utils/dates';

/** Before/after slider comparing the earliest and latest photo entries. */
function BeforeAfter({ before, after }: { before: { src: string; date: string }; after: { src: string; date: string } }) {
  const [split, setSplit] = useState(50);
  return (
    <Card className="before-after">
      <div className="before-after__frame" style={{ ['--split' as string]: `${split}%` }}>
        <img src={after.src} alt={`After, ${formatDate(after.date)}`} />
        <img src={before.src} alt={`Before, ${formatDate(before.date)}`} className="before-after__before" />
        <span className="before-after__label before-after__label--left">{formatDate(before.date, { month: 'short', year: 'numeric' })}</span>
        <span className="before-after__label before-after__label--right">{formatDate(after.date, { month: 'short', year: 'numeric' })}</span>
        <span className="before-after__handle" aria-hidden />
      </div>
      <label className="visually-hidden" htmlFor="ba-range">
        Compare before and after
      </label>
      <input id="ba-range" type="range" min={0} max={100} value={split} onChange={(e) => setSplit(Number(e.target.value))} className="before-after__range" />
    </Card>
  );
}

export function JournalScreen({ plantId }: { plantId: string }) {
  const { plants, journal } = useData();
  const router = useRouter();
  const plant = plants.find((p) => p.id === plantId);
  const entries = useMemo(() => journal.filter((j) => j.plantId === plantId).sort((a, b) => b.entryDate.localeCompare(a.entryDate)), [journal, plantId]);
  const photos = entries.filter((e) => e.imageRef);
  const heights = entries.filter((e) => e.heightCm).map((e) => e.heightCm as number);

  if (!plant) {
    return (
      <PushedScreen title="Journal">
        <ErrorState title="Plant not found" message="This plant may have been deleted." />
      </PushedScreen>
    );
  }

  return (
    <PushedScreen title={`${plant.name}’s journal`} trailing={<IconButton icon={Plus} label="Add journal entry" onClick={() => router.openSheet({ name: 'addJournal', plantId })} />}>
      {entries.length === 0 ? (
        <EmptyState
          illustration="journal"
          title="Start a growth journal"
          message={`Record new leaves, repotting or changes in ${plant.name}. Add photos to compare growth over time.`}
          action={
            <PrimaryButton icon={Plus} onClick={() => router.openSheet({ name: 'addJournal', plantId })}>
              Add first entry
            </PrimaryButton>
          }
        />
      ) : (
        <>
          {heights.length >= 2 && (
            <Card className="growth-summary">
              <Ruler size={20} aria-hidden />
              <p className="t-subhead">
                Grew <strong className="t-numeric">{(heights[0] - heights[heights.length - 1]).toFixed(0)} cm</strong> across {heights.length} measurements.
              </p>
            </Card>
          )}
          {photos.length >= 2 && (
            <section aria-labelledby="ba-heading">
              <SectionHeader title="Before & after" id="ba-heading" />
              <BeforeAfter before={{ src: photos[photos.length - 1].imageRef!, date: photos[photos.length - 1].entryDate }} after={{ src: photos[0].imageRef!, date: photos[0].entryDate }} />
            </section>
          )}
          <SectionHeader title="Timeline" />
          <ol className="timeline">
            {entries.map((e) => (
              <li key={e.id} className="timeline__item">
                <span className="timeline__dot" aria-hidden />
                <div className="timeline__content">
                  <div className="timeline__head">
                    <p className="t-footnote t-secondary">
                      {formatDate(e.entryDate, { weekday: 'short', day: 'numeric', month: 'short', year: 'numeric' })}
                      {e.heightCm ? ` · ${e.heightCm} cm` : ''}
                    </p>
                    <IconButton icon={Pencil} label={`Edit entry from ${formatDate(e.entryDate)}`} onClick={() => router.openSheet({ name: 'editJournal', entryId: e.id })} />
                  </div>
                  <p className="t-body">{e.notes}</p>
                  {e.imageRef && <img src={e.imageRef} alt={`Journal photo from ${formatDate(e.entryDate)}`} className="timeline__photo" loading="lazy" />}
                </div>
              </li>
            ))}
          </ol>
        </>
      )}
    </PushedScreen>
  );
}
