import { useId, useState, type FormEvent } from 'react';
import { useRouter } from '../../app/router';
import { FormSection, NumberField, SelectField, TextAreaField, TextField, Toggle } from '../../components/FormFields';
import { Sheet } from '../../components/Sheet';
import { useToast } from '../../components/Toast';
import { careCategories } from '../../data/catalog';
import { useData } from '../../data/store';
import type { CareCategory, CareTaskDraft } from '../../types/models';
import { addDays, fromDateInput, startOfDay, toDateInput } from '../../utils/dates';
import { hasErrors, NAME_MAX, validateTask, type ValidationErrors } from '../../utils/validation';

export function TaskFormSheet({ taskId, plantId }: { taskId?: string; plantId?: string }) {
  const { tasks, plants, preferences, actions } = useData();
  const router = useRouter();
  const toast = useToast();
  const formId = useId();
  const existing = taskId ? tasks.find((t) => t.id === taskId) : undefined;

  const [draft, setDraft] = useState<CareTaskDraft>(() =>
    existing
      ? { plantId: existing.plantId, title: existing.title, descriptionText: existing.descriptionText, category: existing.category, dueDate: existing.dueDate, recurrenceIntervalDays: existing.recurrenceIntervalDays, notes: existing.notes }
      : {
          plantId,
          title: '',
          category: 'watering',
          dueDate: (() => {
            const d = addDays(startOfDay(new Date()), 1);
            d.setHours(preferences.reminderHour);
            return d.toISOString();
          })(),
        },
  );
  const [repeats, setRepeats] = useState(!!existing?.recurrenceIntervalDays);
  const [errors, setErrors] = useState<ValidationErrors<CareTaskDraft>>({});
  const [busy, setBusy] = useState(false);

  const set = <K extends keyof CareTaskDraft>(key: K, value: CareTaskDraft[K]) => {
    setDraft((d) => ({ ...d, [key]: value }));
    if (errors[key]) setErrors((e) => ({ ...e, [key]: undefined }));
  };

  const plantName = plants.find((p) => p.id === draft.plantId)?.name;
  const suggestTitle = (category: CareCategory) => {
    const verb = careCategories.find((c) => c.id === category)?.verb ?? 'Care for';
    return plantName ? `${verb} ${plantName}` : '';
  };

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    const candidate: CareTaskDraft = { ...draft, title: draft.title.trim() || suggestTitle(draft.category), recurrenceIntervalDays: repeats ? draft.recurrenceIntervalDays : undefined };
    const found = validateTask(candidate);
    if (repeats && !candidate.recurrenceIntervalDays) found.recurrenceIntervalDays = 'Enter how many days between repeats.';
    setErrors(found);
    if (hasErrors(found)) {
      requestAnimationFrame(() => document.querySelector<HTMLElement>('.sheet [aria-invalid="true"]')?.focus());
      return;
    }
    setBusy(true);
    try {
      if (existing) await actions.updateTask(existing.id, candidate);
      else await actions.addTask(candidate);
      router.closeSheet();
      toast(existing ? 'Care task updated.' : 'Care task added.');
    } catch (err) {
      toast(err instanceof Error ? err.message : 'Could not save the task.', { kind: 'error' });
    } finally {
      setBusy(false);
    }
  };

  const hour = new Date(draft.dueDate).getHours();
  return (
    <Sheet title={existing ? 'Edit care task' : 'New care task'} onCancel={router.closeSheet} formId={formId} busy={busy} confirmLabel={existing ? 'Save' : 'Add'}>
      <form id={formId} onSubmit={submit} noValidate className="form">
        <FormSection title="Task">
          <SelectField label="Plant" value={draft.plantId} options={plants.map((p) => ({ id: p.id, label: p.name }))} onChange={(v) => set('plantId', v)} placeholder="No specific plant" />
          <SelectField label="Care type" value={draft.category} options={careCategories} onChange={(v) => v && set('category', v)} required />
          <TextField label="Title" value={draft.title} onChange={(v) => set('title', v)} error={errors.title} maxLength={NAME_MAX + 10} placeholder={suggestTitle(draft.category) || 'e.g. Water the herbs'} hint={!draft.title && suggestTitle(draft.category) ? `Leave blank to use “${suggestTitle(draft.category)}”.` : undefined} />
          <TextAreaField label="Description" value={draft.descriptionText ?? ''} onChange={(v) => set('descriptionText', v)} rows={2} placeholder="How to do it (optional)" />
        </FormSection>
        <FormSection title="Schedule">
          <TextField label="Due date" type="date" value={toDateInput(draft.dueDate)} onChange={(v) => set('dueDate', fromDateInput(v, hour) ?? '')} error={errors.dueDate} required />
          <Toggle label="Repeat" description="When completed, the next occurrence is scheduled automatically." checked={repeats} onChange={setRepeats} />
          {repeats && <NumberField label="Repeat every" suffix="days" value={draft.recurrenceIntervalDays} onChange={(v) => set('recurrenceIntervalDays', v)} error={errors.recurrenceIntervalDays} placeholder="7" />}
        </FormSection>
        <FormSection title="Notes">
          <TextAreaField label="Notes" value={draft.notes ?? ''} onChange={(v) => set('notes', v)} rows={2} />
        </FormSection>
      </form>
    </Sheet>
  );
}
