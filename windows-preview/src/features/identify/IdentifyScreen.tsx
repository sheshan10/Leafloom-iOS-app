import { Camera, FlaskConical, ImagePlus, RefreshCw, ScanLine, X } from 'lucide-react';
import { useRef } from 'react';
import { useRouter } from '../../app/router';
import { GhostButton, PrimaryButton, SecondaryButton } from '../../components/Button';
import { SectionHeader, TabScreen } from '../../components/Layout';
import { ErrorState, LoadingView } from '../../components/States';
import { knowledgeBase } from '../../data/knowledge';
import { useData } from '../../data/store';
import { formatDate } from '../../utils/dates';
import { fileToDownsampledDataUrl } from '../../utils/images';
import { useIdentifyFlow } from './IdentifyFlow';

const samplePhotos = knowledgeBase.filter((e) => e.image);

export function IdentifyScreen() {
  const flow = useIdentifyFlow();
  const router = useRouter();
  const { identifications, plants } = useData();
  const fileRef = useRef<HTMLInputElement>(null);

  const onFile = async (file?: File) => {
    if (!file) return;
    try {
      flow.selectImage(await fileToDownsampledDataUrl(file));
    } catch (e) {
      flow.setError(e instanceof Error ? e.message : 'That image could not be used.');
    }
  };

  const analyse = async () => {
    const r = await flow.analyse();
    if (r) router.push({ name: 'identifyResult' });
  };

  const recent = [...identifications].sort((a, b) => b.dateCreated.localeCompare(a.dateCreated)).slice(0, 5);

  return (
    <TabScreen title="Identify" subtitle="AI-assisted">
      <div className="demo-banner" role="note">
        <FlaskConical size={18} aria-hidden />
        <p>
          <strong>Simulated in this preview.</strong> No machine learning runs in the browser. The iPhone app uses an on-device Core ML model when one is installed.
        </p>
      </div>

      <div className={`viewfinder ${flow.status === 'processing' ? 'is-scanning' : ''}`}>
        {flow.image ? (
          <img src={flow.image} alt="Selected photo to identify" className="viewfinder__image" />
        ) : (
          <div className="viewfinder__empty">
            <ScanLine size={40} aria-hidden />
            <p className="t-headline">Choose a clear photo of one plant</p>
            <p className="t-footnote t-secondary">Fill the frame with leaves in good light for the best suggestion.</p>
          </div>
        )}
        <span className="viewfinder__corner viewfinder__corner--tl" aria-hidden />
        <span className="viewfinder__corner viewfinder__corner--tr" aria-hidden />
        <span className="viewfinder__corner viewfinder__corner--bl" aria-hidden />
        <span className="viewfinder__corner viewfinder__corner--br" aria-hidden />
        {flow.status === 'processing' && <span className="viewfinder__scanline" aria-hidden />}
        {flow.image && flow.status !== 'processing' && (
          <button type="button" className="viewfinder__clear" aria-label="Remove selected photo" onClick={flow.clear}>
            <X size={16} aria-hidden />
          </button>
        )}
      </div>

      <input ref={fileRef} type="file" accept="image/*" hidden aria-label="Photo to identify" onChange={(e) => void onFile(e.target.files?.[0])} />

      {flow.status === 'processing' ? (
        <div className="identify-processing">
          <LoadingView compact label="Analysing photo… (simulated)" />
          <GhostButton icon={X} onClick={flow.cancel}>
            Cancel
          </GhostButton>
        </div>
      ) : flow.status === 'error' ? (
        <ErrorState title="Can’t use this photo" message={flow.error ?? 'Something went wrong.'} onRetry={() => fileRef.current?.click()} />
      ) : (
        <div className="identify-actions">
          {flow.image ? (
            <>
              <PrimaryButton icon={ScanLine} fullWidth onClick={() => void analyse()}>
                Identify plant
              </PrimaryButton>
              <SecondaryButton icon={RefreshCw} fullWidth onClick={() => fileRef.current?.click()}>
                Choose another photo
              </SecondaryButton>
            </>
          ) : (
            <>
              <PrimaryButton icon={ImagePlus} fullWidth onClick={() => fileRef.current?.click()}>
                Choose from library
              </PrimaryButton>
              <SecondaryButton icon={Camera} fullWidth disabled title="The camera is available in the native iPhone app">
                Take photo (iPhone only)
              </SecondaryButton>
            </>
          )}
        </div>
      )}

      {!flow.image && (
        <section aria-labelledby="try-sample">
          <SectionHeader title="Try a sample photo" id="try-sample" />
          <div className="sample-photos">
            {samplePhotos.map((e) => (
              <button key={e.key} type="button" className="sample-photo" onClick={() => flow.selectImage(`/images/plants/${e.image}`)} aria-label={`Use sample photo of ${e.commonName}`}>
                <img src={`/images/plants/${e.image}`} alt="" loading="lazy" />
              </button>
            ))}
          </div>
        </section>
      )}

      {recent.length > 0 && (
        <section aria-labelledby="id-history">
          <SectionHeader title="Recent identifications" id="id-history" />
          <ul className="list-card id-history">
            {recent.map((r) => {
              const linked = r.plantId ? plants.find((p) => p.id === r.plantId) : undefined;
              return (
                <li key={r.id} className="id-history__row">
                  {r.imageRef && <img src={r.imageRef} alt="" className="id-history__thumb" />}
                  <span className="id-history__text">
                    <span className="t-headline">{r.predictedLabel}</span>
                    <span className="t-footnote t-secondary">
                      {formatDate(r.dateCreated, { day: 'numeric', month: 'short' })} · {r.isDemoResult ? 'Simulated result' : 'Model prediction'}
                      {linked ? ` · saved as ${linked.name}` : ''}
                    </span>
                  </span>
                </li>
              );
            })}
          </ul>
        </section>
      )}
    </TabScreen>
  );
}
