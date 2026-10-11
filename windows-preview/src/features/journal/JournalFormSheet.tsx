import { ImagePlus, Trash2, X } from 'lucide-react';
import { useId, useRef, useState, type FormEvent } from 'react';
import { useRouter } from '../../app/router';
import { DangerButton } from '../../components/Button';
import { ConfirmDialog } from '../../components/ConfirmDialog';
import { FormSection, NumberField, SelectField, TextAreaField, TextField } from '../../components/FormFields';
import { Sheet } from '../../components/Sheet';
import { useToast } from '../../components/Toast';
import { useData } from '../../data/store';
import type { JournalDraft } from '../../types/models';
import { fromDateInput, toDateInput } from '../../utils/dates';
import { fileToDownsampledDataUrl } from '../../utils/images';
import { hasErrors, validateJournal, type ValidationErrors } from '../../utils/validation';

export function JournalFormSheet({ entryId, plantId }: { entryId?: string; plantId?: string }) {
  const { journal, plants, actions } = useData();
  const router = useRouter();
  const toast = useToast();
  const formId = useId();
  const fileRef = useRef<HTMLInputElement>(null);
  const existing = entryId ? journal.find((j) => j.id === entryId) : undefined;

  const [draft, setDraft] = useState<JournalDraft>(() =>
    existing
      ? { plantId: existing.plantId, entryDate: existing.entryDate, notes: existing.notes, imageRef: existing.imageRef, heightCm: existing.heightCm }
      : { plantId: plantId ?? '', entryDate: new Date().toISOString(), notes: '' },
  );
  const [errors, setErrors] = useState<ValidationErrors<JournalDraft>>({});
  const [photoError, setPhotoError] = useState<string>();
  const [busy, setBusy] = useState(false);
  const [confirm, setConfirm] = useState(false);

  const set = <K extends keyof JournalDraft>(key: K, value: JournalDraft[K]) => {
    setDraft((d) => ({ ...d, [key]: value }));
    if (errors[key]) setErrors((e) => ({ ...e, [key]: undefined }));
  };

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    const found = validateJournal(draft);
    setErrors(found);
    if (hasErrors(found)) {
      requestAnimationFrame(() => document.querySelector<HTMLElement>('.sheet [aria-invalid="true"]')?.focus());
      return;
    }
    setBusy(true);
    try {
      if (existing) await actions.updateJournal(existing.id, draft);
      else await actions.addJournal(draft);
      router.closeSheet();
      toast(existing ? 'Journal entry updated.' : 'Journal entry added.');
    } catch (err) {
      toast(err instanceof Error ? err.message : 'Could not save the entry.', { kind: 'error' });
    } finally {
      setBusy(false);
    }
  };

  const onDelete = async () => {
    if (!existing) return;
    setConfirm(false);
    try {
      await actions.deleteJournal(existing.id);
      router.closeSheet();
      toast('Journal entry deleted.');
    } catch (err) {
      toast(err instanceof Error ? err.message : 'Could not delete the entry.', { kind: 'error' });
    }
  };

  return (
    <Sheet title={existing ? 'Edit entry' : 'New journal entry'} onCancel={router.closeSheet} formId={formId} busy={busy} confirmLabel={existing ? 'Save' : 'Add'}>
      <form id={formId} onSubmit={submit} noValidate className="form">
        <FormSection>
          <SelectField label="Plant" value={draft.plantId || undefined} options={plants.map((p) => ({ id: p.id, label: p.name }))} onChange={(v) => set('plantId', v ?? '')} error={errors.plantId} required placeholder="Choose a plant" />
          <TextField label="Date" type="date" value={toDateInput(draft.entryDate)} onChange={(v) => set('entryDate', fromDateInput(v, 12) ?? '')} error={errors.entryDate} required max={toDateInput(new Date().toISOString())} />
          <TextAreaField label="What did you notice?" value={draft.notes} onChange={(v) => set('notes', v)} error={errors.notes} placeholder="New leaf, repotted, moved to brighter spot…" rows={4} />
          <NumberField label="Height (optional)" suffix="cm" value={draft.heightCm} onChange={(v) => set('heightCm', v)} error={errors.heightCm} />
        </FormSection>
        <div className="photo-picker">
          {draft.imageRef ? (
            <div className="photo-picker__preview">
              <img src={draft.imageRef} alt="Journal photo" />
              <button type="button" className="photo-picker__remove" aria-label="Remove photo" onClick={() => set('imageRef', undefined)}>
                <X size={16} aria-hidden />
              </button>
            </div>
          ) : (
            <button type="button" className="photo-picker__empty" onClick={() => fileRef.current?.click()}>
              <ImagePlus size={24} aria-hidden />
              <span>Attach a photo</span>
            </button>
          )}
          <input
            ref={fileRef}
            type="file"
            accept="image/*"
            hidden
            aria-label="Journal photo"
            onChange={async (e) => {
              const f = e.target.files?.[0];
              if (!f) return;
              try {
                setPhotoError(undefined);
                set('imageRef', await fileToDownsampledDataUrl(f));
              } catch (err) {
                setPhotoError(err instanceof Error ? err.message : 'That photo could not be used.');
              }
            }}
          />
          {photoError && (
            <p className="field__error" role="alert">
              {photoError}
            </p>
          )}
        </div>
        {existing && (
          <DangerButton icon={Trash2} fullWidth onClick={() => setConfirm(true)}>
            Delete entry
          </DangerButton>
        )}
      </form>
      <ConfirmDialog open={confirm} title="Delete this journal entry?" message="The note and photo will be permanently removed." confirmLabel="Delete entry" onConfirm={() => void onDelete()} onCancel={() => setConfirm(false)} />
    </Sheet>
  );
}
