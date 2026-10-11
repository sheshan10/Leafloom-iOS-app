import { ArrowRight, BellRing, Check } from 'lucide-react';
import { useState } from 'react';
import { PrimaryButton, SecondaryButton } from '../../components/Button';
import { BrandMark } from '../../components/Icons';
import { useData } from '../../data/store';
import { SimulatedPermissionPrompt } from '../settings/SimulatedPermissionPrompt';

const pages = [
  {
    art: null,
    eyebrow: 'Welcome to',
    title: 'LeafLoom',
    body: 'Your calm, private companion for keeping plants thriving. Everything stays on your device — no account needed.',
  },
  {
    art: '/illustrations/onboarding-collection.svg',
    eyebrow: 'Your collection',
    title: 'Every plant, beautifully organised',
    body: 'Keep photos, care needs, locations and notes for each plant. Search, filter and favourite in seconds.',
  },
  {
    art: '/illustrations/onboarding-identify.svg',
    eyebrow: 'AI-assisted',
    title: 'Identify plants from a photo',
    body: 'On iPhone, an on-device Core ML model suggests what your plant might be. Suggestions are a starting point, not a guarantee.',
  },
  {
    art: '/illustrations/onboarding-reminders.svg',
    eyebrow: 'Personal care',
    title: 'Reminders that fit your plants',
    body: 'Recurring watering, feeding and pruning schedules, with gentle reminders when something is due.',
  },
];

export function Onboarding() {
  const { actions, preferences } = useData();
  const [index, setIndex] = useState(0);
  const [direction, setDirection] = useState<'next' | 'prev'>('next');
  const [prompt, setPrompt] = useState(false);
  const last = index === pages.length - 1;
  const page = pages[index];

  const finish = () => void actions.updatePreferences({ onboardingComplete: true });
  const goTo = (i: number) => {
    setDirection(i > index ? 'next' : 'prev');
    setIndex(i);
  };

  return (
    <div className="onboarding">
      <div className="onboarding__top">
        {!last ? (
          <button type="button" className="text-btn" onClick={finish}>
            Skip
          </button>
        ) : (
          <span />
        )}
      </div>

      <div key={index} className={`onboarding__page onboarding__page--${direction}`} aria-live="polite">
        <div className="onboarding__art">
          {page.art ? (
            <img src={page.art} alt="" aria-hidden />
          ) : (
            <div className="onboarding__brand">
              <BrandMark size={120} />
            </div>
          )}
        </div>
        <p className="t-eyebrow">{page.eyebrow}</p>
        <h1 className={index === 0 ? 't-large-title onboarding__wordmark' : 't-title'}>{page.title}</h1>
        {index === 0 && <p className="onboarding__tagline">Grow with confidence.</p>}
        <p className="t-body t-secondary onboarding__body">{page.body}</p>

        {last && (
          <div className="onboarding__reminder">
            {preferences.notificationPermission === 'granted' ? (
              <p className="inline-success">
                <Check size={16} aria-hidden /> Reminders are on. You can change this any time in Settings.
              </p>
            ) : preferences.notificationPermission === 'denied' ? (
              <p className="t-footnote t-secondary">Reminders are off. LeafLoom still works fully — you can enable them later in Settings.</p>
            ) : (
              <SecondaryButton icon={BellRing} fullWidth onClick={() => setPrompt(true)}>
                Turn on care reminders
              </SecondaryButton>
            )}
          </div>
        )}
      </div>

      <div className="onboarding__bottom">
        <div className="page-dots" role="tablist" aria-label="Onboarding progress">
          {pages.map((p, i) => (
            <button
              key={p.title}
              type="button"
              role="tab"
              aria-selected={i === index}
              aria-label={`Page ${i + 1} of ${pages.length}`}
              className={`page-dots__dot ${i === index ? 'is-active' : ''}`}
              onClick={() => goTo(i)}
            />
          ))}
        </div>
        {last ? (
          <PrimaryButton fullWidth icon={ArrowRight} onClick={finish}>
            Get Started
          </PrimaryButton>
        ) : (
          <PrimaryButton fullWidth icon={ArrowRight} onClick={() => goTo(index + 1)}>
            Continue
          </PrimaryButton>
        )}
      </div>

      <SimulatedPermissionPrompt
        open={prompt}
        onResult={(granted) => {
          setPrompt(false);
          void actions.updatePreferences({ notificationPermission: granted ? 'granted' : 'denied', remindersEnabled: granted });
        }}
      />
    </div>
  );
}
