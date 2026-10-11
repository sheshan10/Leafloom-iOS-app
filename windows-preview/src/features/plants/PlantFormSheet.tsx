import { Camera, ImagePlus, X } from 'lucide-react';
import { useId, useRef, useState, type FormEvent } from 'react';
import { useRouter } from '../../app/router';
import { FormSection, NumberField, SelectField, TextAreaField, TextField, Toggle } from '../../components/FormFields';
import { Sheet } from '../../components/Sheet';
import { useToast } from '../../components/Toast';
import { humidityOptions, identificationStatusOptions, plantCategories, sunlightOptions } from '../../data/catalog';
import { useData } from '../../data/store';
import type { PlantDraft } from '../../types/models';
import { fromDateInput, toDateInput } from '../../utils/dates';
import { fileToDownsampledDataUrl } from '../../utils/images';
import { hasErrors, NAME_MAX, parseTags, validatePlant, type ValidationErrors } from '../../utils/validation';

const blankDraft: PlantDraft = {
  name: '',
  category: 'foliage',
  identificationStatus: 'unknown',
  tags: [],
  isFavorite: false,
};

interface Props {
  plantId?: string;
  prefill?: Partial<PlantDraft>;
  identificationId?: string;
}

export function PlantFormSheet({ plantId, prefill, identificationId }: Props) {
  const { plants, preferences, actions } = useData();
  const router = useRouter();
  const toast = useToast();
  const formId = useId();
  const fileRef = useRef<HTMLInputElement>(null);
  const existing = plantId ? plants.find((p) => p.id === plantId) : undefined;
  const isEdit = !!existing;

  const [draft, setDraft] = useState<PlantDraft>(() => (existing ? { ...existing } : { ...blankDraft, ...prefill }));
  const [tagsText, setTagsText] = useState(() => (existing?.tags ?? prefill?.tags ?? []).join(', '));
  const [createSchedule, setCreateSchedule] = useState(true);
  const [errors, setErrors] = useState<ValidationErrors<PlantDraft>>({});
  const [photoError, setPhotoError] = useState<string>();
  const [busy, setBusy] = useState(false);

  const set = <K extends keyof PlantDraft>(key: K, value: PlantDraft[K]) => {
    setDraft((d) => ({ ...d, [key]: value }));
    if (errors[key]) setErrors((e) => ({ ...e, [key]: undefined }));
  };

  const onPhoto = async (file?: File) => {
    if (!file) return;
    setPhotoError(undefined);
    try {
      set('imageRef', await fileToDownsampledDataUrl(file));
    } catch (e) {
      setPhotoError(e instanceof Error ? e.message : 'That photo could not be used.');
    }
  };

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    const candidate = { ...draft, tags: parseTags(tagsText) };
    const found = validatePlant(candidate);
    setErrors(found);
    if (hasErrors(found)) {
      requestAnimationFrame(() => document.querySelector<HTMLElement>('.sheet [aria-invalid="true"]')?.focus());
      return;
    }
    setBusy(true);
    try {
      if (existing) {
        await actions.updatePlant(existing.id, candidate);
        router.closeSheet();
        toast(`Saved changes to ${candidate.name.trim()}.`);
      } else {
        const plant = await actions.addPlant(candidate, { createCareSchedule: createSchedule, reminderHour: preferences.reminderHour });
        if (identificationId) await actions.linkIdentification(identificationId, plant.id);
        router.closeSheet();
        router.push({ name: 'plantDetails', plantId: plant.id }, 'plants');
        toast(`${plant.name} added to My Plants.`);
      }
    } catch (err) {
      toast(err instanceof Error ? err.message : 'Could not save the plant.', { kind: 'error' });
    } finally {
      setBusy(false);
    }
  };

  return (
    <Sheet title={isEdit ? 'Edit plant' : 'Add plant'} onCancel={router.closeSheet} formId={formId} busy={busy} confirmLabel={isEdit ? 'Save' : 'Add'}>
      <form id={formId} onSubmit={submit} noValidate className="form">
        <div className="photo-picker">
          {draft.imageRef ? (
            <div className="photo-picker__preview">
              <img src={draft.imageRef} alt="Selected plant photo" />
              <button type="button" className="photo-picker__remove" aria-label="Remove photo" onClick={() => set('imageRef', undefined)}>
                <X size={16} aria-hidden />
              </button>
            </div>
          ) : (
            <button type="button" className="photo-picker__empty" onClick={() => fileRef.current?.click()}>
              <ImagePlus size={28} aria-hidden />
              <span>Add a photo</span>
              <span className="t-footnote t-secondary">Optional</span>
            </button>
          )}
          {draft.imageRef && (
            <button type="button" className="text-btn" onClick={() => fileRef.current?.click()}>
              <Camera size={16} aria-hidden /> Choose another photo
            </button>
          )}
          <input ref={fileRef} type="file" accept="image/*" hidden onChange={(e) => void onPhoto(e.target.files?.[0])} aria-label="Plant photo" />
          {photoError && (
            <p className="field__error" role="alert">
              {photoError}
            </p>
          )}
        </div>

        <FormSection title="Basics">
          <TextField label="Plant name" value={draft.name} onChange={(v) => set('name', v)} error={errors.name} required maxLength={NAME_MAX + 10} placeholder="e.g. Monty" autoFocus={!isEdit} hint="A nickname or the name you use for this plant." />
          <TextField label="Common name" value={draft.commonName ?? ''} onChange={(v) => set('commonName', v)} placeholder="e.g. Swiss cheese plant" />
          <TextField label="Scientific name" value={draft.scientificName ?? ''} onChange={(v) => set('scientificName', v)} placeholder="e.g. Monstera deliciosa" hint="Leave blank if you’re not sure." />
          <SelectField label="Category" value={draft.category} options={plantCategories} onChange={(v) => v && set('category', v)} error={errors.category} required placeholder="Choose a category" />
          <SelectField label="Identification status" value={draft.identificationStatus} options={identificationStatusOptions} onChange={(v) => set('identificationStatus', v ?? 'unknown')} />
        </FormSection>

        <FormSection title="Where & when">
          <TextField label="Location" value={draft.location ?? ''} onChange={(v) => set('location', v)} placeholder="e.g. Living room" />
          <TextField label="Acquisition date" type="date" value={toDateInput(draft.acquisitionDate)} onChange={(v) => set('acquisitionDate', v ? fromDateInput(v, 12) : undefined)} error={errors.acquisitionDate} max={toDateInput(new Date().toISOString())} />
        </FormSection>

        <FormSection title="Care needs" footer="Intervals drive recurring reminders. You can leave any of these blank.">
          <div className="form-row">
            <NumberField label="Water every" suffix="days" value={draft.wateringIntervalDays} onChange={(v) => set('wateringIntervalDays', v)} error={errors.wateringIntervalDays} placeholder="7" />
            <NumberField label="Fertilise every" suffix="days" value={draft.fertilizingIntervalDays} onChange={(v) => set('fertilizingIntervalDays', v)} error={errors.fertilizingIntervalDays} placeholder="30" />
          </div>
          <SelectField label="Sunlight" value={draft.sunlightPreference} options={sunlightOptions} onChange={(v) => set('sunlightPreference', v)} />
          <SelectField label="Humidity" value={draft.humidityPreference} options={humidityOptions} onChange={(v) => set('humidityPreference', v)} />
          <TextField label="Soil" value={draft.soilPreference ?? ''} onChange={(v) => set('soilPreference', v)} placeholder="e.g. Chunky aroid mix" />
          {!isEdit && (
            <Toggle
              label="Create care schedule"
              description="Adds recurring watering and fertilising tasks from the intervals above."
              checked={createSchedule && !!(draft.wateringIntervalDays || draft.fertilizingIntervalDays)}
              onChange={setCreateSchedule}
            />
          )}
        </FormSection>

        <FormSection title="Notes & tags">
          <TextAreaField label="Notes" value={draft.notes ?? ''} onChange={(v) => set('notes', v)} error={errors.notes} placeholder="Anything worth remembering…" />
          <TextField label="Tags" value={tagsText} onChange={setTagsText} placeholder="e.g. trailing, gift" hint="Separate tags with commas." />
          <Toggle label="Favourite" checked={draft.isFavorite} onChange={(v) => set('isFavorite', v)} />
        </FormSection>
      </form>
    </Sheet>
  );
}
