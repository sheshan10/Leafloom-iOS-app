import { Droplets, FlaskConical, History, Info, Plus, Sprout, Sun, Waves, Wind } from 'lucide-react';
import { useState } from 'react';
import { useRouter } from '../../app/router';
import { PrimaryButton, SecondaryButton } from '../../components/Button';
import { CategoryIcon } from '../../components/Icons';
import { Card, PushedScreen, SectionHeader } from '../../components/Layout';
import { ErrorState } from '../../components/States';
import { useToast } from '../../components/Toast';
import { categoryLabel, humidityOptions, labelFor, sunlightOptions } from '../../data/catalog';
import { knowledgeDisclaimer } from '../../data/knowledge';
import { useData } from '../../data/store';
import { useIdentifyFlow } from './IdentifyFlow';

export function IdentifyResultScreen() {
  const flow = useIdentifyFlow();
  const router = useRouter();
  const toast = useToast();
  const { actions } = useData();
  const [saving, setSaving] = useState(false);

  if (!flow.result || !flow.image) {
    return (
      <PushedScreen title="Results">
        <ErrorState title="No result" message="Choose a photo on the Identify screen first." />
      </PushedScreen>
    );
  }
  const { top, alternatives } = flow.result;
  const entry = top.entry;

  const saveHistory = async () => {
    if (flow.savedRecordId) return flow.savedRecordId;
    const rec = await actions.saveIdentification({
      imageRef: flow.image,
      predictedLabel: top.label,
      modelIdentifier: flow.result!.modelIdentifier,
      isDemoResult: true,
    });
    flow.markSaved(rec.id);
    return rec.id;
  };

  const onSaveHistory = async () => {
    setSaving(true);
    try {
      await saveHistory();
      toast('Saved to identification history.');
    } catch (e) {
      toast(e instanceof Error ? e.message : 'Could not save.', { kind: 'error' });
    } finally {
      setSaving(false);
    }
  };

  const onAddPlant = async () => {
    try {
      const identificationId = await saveHistory();
      router.openSheet({
        name: 'addPlant',
        identificationId,
        prefill: {
          name: entry?.commonName ?? top.label,
          commonName: entry?.commonName,
          scientificName: entry?.scientificName,
          category: entry?.category ?? 'foliage',
          identificationStatus: 'suggested',
          imageRef: flow.image,
          wateringIntervalDays: entry?.wateringIntervalDays,
          fertilizingIntervalDays: entry?.fertilizingIntervalDays,
          sunlightPreference: entry?.sunlight,
          humidityPreference: entry?.humidity,
          soilPreference: entry?.soil,
        },
      });
    } catch (e) {
      toast(e instanceof Error ? e.message : 'Could not continue.', { kind: 'error' });
    }
  };

  return (
    <PushedScreen title="Identification results" backLabel="Identify">
      <div className="result-hero">
        <img src={flow.image} alt="Photo that was identified" className="result-hero__image" />
        <span className="result-hero__tag">
          <FlaskConical size={14} aria-hidden /> Demo identification
        </span>
      </div>

      <div className="demo-banner demo-banner--amber" role="note">
        <Info size={18} aria-hidden />
        <p>Demo identification — connect a compatible Core ML model for real predictions. No confidence score is shown because none was calculated.</p>
      </div>

      <Card className="result-card result-card--top">
        <p className="t-eyebrow">Suggested plant</p>
        <h1 className="t-title">{top.label}</h1>
        {entry && <p className="result-card__scientific">{entry.scientificName}</p>}
        {entry && (
          <p className="result-card__category">
            <CategoryIcon category={entry.category} size={16} /> {categoryLabel(entry.category)}
          </p>
        )}
        {entry && <p className="t-subhead">{entry.summary}</p>}
      </Card>

      {entry && (
        <section aria-labelledby="general-care">
          <SectionHeader title="General care" id="general-care" />
          <Card className="care-facts">
            <div className="care-fact">
              <span className="care-fact__icon" aria-hidden><Droplets size={18} /></span>
              <span className="care-fact__label">Watering</span>
              <span className="care-fact__value">About every {entry.wateringIntervalDays} days</span>
            </div>
            <div className="care-fact">
              <span className="care-fact__icon" aria-hidden><Sprout size={18} /></span>
              <span className="care-fact__label">Fertilising</span>
              <span className="care-fact__value">About every {entry.fertilizingIntervalDays} days</span>
            </div>
            <div className="care-fact">
              <span className="care-fact__icon" aria-hidden><Sun size={18} /></span>
              <span className="care-fact__label">Light</span>
              <span className="care-fact__value">{labelFor(sunlightOptions, entry.sunlight)}</span>
            </div>
            <div className="care-fact">
              <span className="care-fact__icon" aria-hidden><Wind size={18} /></span>
              <span className="care-fact__label">Humidity</span>
              <span className="care-fact__value">{labelFor(humidityOptions, entry.humidity)}</span>
            </div>
            <div className="care-fact">
              <span className="care-fact__icon" aria-hidden><Waves size={18} /></span>
              <span className="care-fact__label">Soil</span>
              <span className="care-fact__value">{entry.soil}</span>
            </div>
          </Card>
          <p className="t-footnote t-secondary disclaimer">{knowledgeDisclaimer}</p>
        </section>
      )}

      {alternatives.length > 0 && (
        <section aria-labelledby="alternatives">
          <SectionHeader title="Other possibilities" id="alternatives" />
          <ul className="list-card alt-list">
            {alternatives.map((a) => (
              <li key={a.label} className="alt-list__row">
                {a.entry && <CategoryIcon category={a.entry.category} size={18} />}
                <span>
                  <span className="t-headline">{a.label}</span>
                  {a.entry && <span className="t-footnote t-secondary"> · {a.entry.scientificName}</span>}
                </span>
              </li>
            ))}
          </ul>
        </section>
      )}

      <p className="t-footnote t-secondary disclaimer">
        Identification suggestions can be wrong. LeafLoom does not diagnose plant diseases; check unusual spots or damage with a local expert.
      </p>

      <div className="details-actions">
        <PrimaryButton icon={Plus} fullWidth onClick={() => void onAddPlant()}>
          Save to My Plants
        </PrimaryButton>
        <SecondaryButton icon={History} fullWidth onClick={() => void onSaveHistory()} disabled={!!flow.savedRecordId} busy={saving}>
          {flow.savedRecordId ? 'Saved to history' : 'Save to history only'}
        </SecondaryButton>
      </div>
    </PushedScreen>
  );
}
