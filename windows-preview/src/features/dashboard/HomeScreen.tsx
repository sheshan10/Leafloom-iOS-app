import { AlertTriangle, CalendarCheck, ChevronRight, Heart, Plus, ScanLine, Settings, Sprout } from 'lucide-react';
import { useCallback, useMemo } from 'react';
import { useRouter } from '../../app/router';
import { IconButton, PrimaryButton, SecondaryButton } from '../../components/Button';
import { CareTaskRow } from '../../components/CareTaskRow';
import { Card, SectionHeader, TabScreen } from '../../components/Layout';
import { PlantThumbnail } from '../../components/PlantThumbnail';
import { ProgressRing } from '../../components/ProgressRing';
import { StatisticCard } from '../../components/StatisticCard';
import { SampleBadge } from '../../components/StatusBadge';
import { EmptyState } from '../../components/States';
import { useData } from '../../data/store';
import { formatLongDate, greeting } from '../../utils/dates';
import { dashboardSummary } from '../../utils/stats';
import { useTaskCompletion } from '../care/useTaskCompletion';

export function HomeScreen() {
  const { plants, tasks } = useData();
  const router = useRouter();
  const toggleTask = useTaskCompletion();
  const now = new Date();
  const summary = useMemo(() => dashboardSummary(plants, tasks), [plants, tasks]);
  const plantById = useMemo(() => new Map(plants.map((p) => [p.id, p])), [plants]);
  const hasSample = plants.some((p) => p.isSample);
  const openPlant = useCallback((id: string) => router.push({ name: 'plantDetails', plantId: id }), [router]);

  const todayTasks = [...summary.overdue, ...summary.dueToday].sort((a, b) => a.dueDate.localeCompare(b.dueDate));
  const upcoming = summary.upcomingWeek.filter((t) => !todayTasks.includes(t)).slice(0, 4);

  return (
    <TabScreen
      title={greeting(now)}
      subtitle={formatLongDate(now)}
      label="Home"
      trailing={<IconButton icon={Settings} label="Settings" onClick={() => router.push({ name: 'settings' })} />}
    >
      {plants.length === 0 ? (
        <EmptyState
          illustration="plants"
          title="Start your garden"
          message="Add your first plant or identify one from a photo. Your dashboard will fill in as you care for them."
          action={
            <div className="stack-sm">
              <PrimaryButton icon={Plus} onClick={() => router.openSheet({ name: 'addPlant' })}>
                Add a plant
              </PrimaryButton>
              <SecondaryButton icon={ScanLine} onClick={() => router.selectTab('identify')}>
                Identify a plant
              </SecondaryButton>
            </div>
          }
        />
      ) : (
        <>
          {hasSample && (
            <div className="sample-banner">
              <SampleBadge />
              <span>You’re viewing sample plants. Reset or erase them in Settings.</span>
            </div>
          )}

          <Card className="progress-card" aria-labelledby="weekly-progress">
            <ProgressRing progress={summary.weeklyProgress} label="Weekly care progress" size={104}>
              <span className="t-numeric progress-card__pct">{Math.round(summary.weeklyProgress * 100)}%</span>
            </ProgressRing>
            <div className="progress-card__text">
              <h2 id="weekly-progress" className="t-headline">
                This week’s care
              </h2>
              <p className="t-subhead t-secondary">
                {summary.completedThisWeek} done ·{' '}
                {todayTasks.length > 0 ? `${todayTasks.length} need attention today` : 'nothing due today'}
              </p>
              <p className="t-footnote t-secondary">{summary.onSchedulePercent}% of plants on schedule</p>
            </div>
          </Card>

          <div className="quick-actions">
            <button type="button" className="quick-action" onClick={() => router.openSheet({ name: 'addPlant' })}>
              <span className="quick-action__icon">
                <Plus size={20} aria-hidden />
              </span>
              Add plant
            </button>
            <button type="button" className="quick-action quick-action--accent" onClick={() => router.selectTab('identify')}>
              <span className="quick-action__icon">
                <ScanLine size={20} aria-hidden />
              </span>
              Identify
            </button>
          </div>

          <div className="stat-grid">
            <StatisticCard icon={Sprout} value={summary.totalPlants} label="Plants" onClick={() => router.selectTab('plants')} />
            <StatisticCard icon={AlertTriangle} value={summary.needsAttention.length} label="Need attention" tone="amber" onClick={() => router.selectTab('care')} />
            <StatisticCard icon={Heart} value={summary.favorites} label="Favourites" tone="danger" />
          </div>

          <section aria-labelledby="today-heading">
            <SectionHeader
              title="Today"
              id="today-heading"
              action={
                <button type="button" className="text-btn" onClick={() => router.selectTab('care')}>
                  All care <ChevronRight size={16} aria-hidden />
                </button>
              }
            />
            {todayTasks.length === 0 ? (
              <div className="inline-empty">
                <CalendarCheck size={20} aria-hidden /> All caught up — nothing due today.
              </div>
            ) : (
              <div className="list-card">
                {todayTasks.map((t) => (
                  <CareTaskRow key={t.id} task={t} plant={t.plantId ? plantById.get(t.plantId) : undefined} onOpen={() => router.push({ name: 'taskDetails', taskId: t.id })} onToggleComplete={() => toggleTask(t)} />
                ))}
              </div>
            )}
          </section>

          {summary.needsAttention.length > 0 && (
            <section aria-labelledby="attention-heading">
              <SectionHeader title="Needs attention" id="attention-heading" />
              <div className="h-scroll" role="list">
                {summary.needsAttention.map((p) => (
                  <button key={p.id} type="button" role="listitem" className="mini-plant" onClick={() => openPlant(p.id)} aria-label={`${p.name} needs attention`}>
                    <PlantThumbnail plant={p} className="mini-plant__image" />
                    <span className="mini-plant__name">{p.name}</span>
                    <span className="mini-plant__flag">
                      <AlertTriangle size={12} aria-hidden /> Care due
                    </span>
                  </button>
                ))}
              </div>
            </section>
          )}

          {upcoming.length > 0 && (
            <section aria-labelledby="upcoming-heading">
              <SectionHeader title="Coming up" id="upcoming-heading" />
              <div className="list-card">
                {upcoming.map((t) => (
                  <CareTaskRow key={t.id} task={t} plant={t.plantId ? plantById.get(t.plantId) : undefined} onOpen={() => router.push({ name: 'taskDetails', taskId: t.id })} onToggleComplete={() => toggleTask(t)} />
                ))}
              </div>
            </section>
          )}

          <section aria-labelledby="recent-heading">
            <SectionHeader
              title="Recently added"
              id="recent-heading"
              action={
                <button type="button" className="text-btn" onClick={() => router.selectTab('plants')}>
                  See all <ChevronRight size={16} aria-hidden />
                </button>
              }
            />
            <div className="h-scroll" role="list">
              {summary.recentlyAdded.map((p) => (
                <button key={p.id} type="button" role="listitem" className="mini-plant mini-plant--large" onClick={() => openPlant(p.id)}>
                  <PlantThumbnail plant={p} className="mini-plant__image" />
                  <span className="mini-plant__name">{p.name}</span>
                  <span className="mini-plant__sub">{p.commonName ?? p.location}</span>
                </button>
              ))}
            </div>
          </section>
        </>
      )}
    </TabScreen>
  );
}
