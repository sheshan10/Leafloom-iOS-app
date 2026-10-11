import { CalendarCheck, CalendarClock, Heart, Sprout } from 'lucide-react';
import { useMemo, type ReactNode } from 'react';
import { Bar, BarChart, CartesianGrid, Cell, Line, LineChart, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import { Card, SectionHeader, TabScreen } from '../../components/Layout';
import { StatisticCard } from '../../components/StatisticCard';
import { EmptyState } from '../../components/States';
import { careCategoryLabel, categoryLabel } from '../../data/catalog';
import { useData } from '../../data/store';
import type { CareCategory } from '../../types/models';
import { additionsByMonth, careByCategory, completionTrend, dashboardSummary, plantsByCategory } from '../../utils/stats';

const palette = ['#214E3D', '#75A77A', '#DDAA52', '#B8CDB6', '#C7794F', '#4F7F6A', '#9DBE8F', '#8A6A3B'];

function ChartCard({ title, description, children, summary }: { title: string; description: string; summary: string; children: ReactNode }) {
  return (
    <Card className="chart-card">
      <h3 className="t-headline">{title}</h3>
      <p className="t-footnote t-secondary">{description}</p>
      <figure className="chart-card__figure" aria-label={`${title}. ${summary}`}>
        <div aria-hidden className="chart-card__chart">
          {children}
        </div>
        <figcaption className="visually-hidden">{summary}</figcaption>
      </figure>
    </Card>
  );
}

const axis = { fontSize: 11, fill: 'var(--color-text-secondary)' };

export function InsightsScreen() {
  const { plants, tasks } = useData();
  const summary = useMemo(() => dashboardSummary(plants, tasks), [plants, tasks]);
  const byCategory = useMemo(() => plantsByCategory(plants).map((c) => ({ ...c, label: categoryLabel(c.category) })), [plants]);
  const additions = useMemo(() => additionsByMonth(plants), [plants]);
  const trend = useMemo(() => completionTrend(tasks), [tasks]);
  const careMix = useMemo(() => careByCategory(tasks).map((c) => ({ ...c, label: careCategoryLabel(c.category as CareCategory) })), [tasks]);
  const totalCompleted = trend.reduce((s, w) => s + w.count, 0);
  const animate = document.documentElement.dataset.reducedMotion !== 'true';

  if (plants.length === 0 && tasks.length === 0) {
    return (
      <TabScreen title="Insights">
        <EmptyState illustration="insights" title="Not enough data yet" message="Add plants and complete a few care tasks. Insights are calculated from your own records." />
      </TabScreen>
    );
  }

  return (
    <TabScreen title="Insights" subtitle="Calculated from your records">
      <div className="stat-grid stat-grid--2">
        <StatisticCard icon={Sprout} value={summary.totalPlants} label="Total plants" />
        <StatisticCard icon={Heart} value={summary.favorites} label="Favourites" tone="danger" />
        <StatisticCard icon={CalendarCheck} value={summary.completedThisWeek} label="Done this week" />
        <StatisticCard icon={CalendarClock} value={summary.upcomingWeek.length} label="Due next 7 days" tone="info" />
      </div>

      <SectionHeader title="Care consistency" />
      {totalCompleted === 0 ? (
        <Card>
          <p className="t-subhead t-secondary">Complete care tasks to see your weekly trend.</p>
        </Card>
      ) : (
        <ChartCard title="Tasks completed per week" description="Last 8 weeks" summary={trend.map((w) => `Week of ${w.label}: ${w.count}`).join('; ')}>
          <ResponsiveContainer width="100%" height={180}>
            <LineChart data={trend} margin={{ top: 8, right: 8, left: -24, bottom: 0 }}>
              <CartesianGrid stroke="var(--color-border)" vertical={false} />
              <XAxis dataKey="label" tick={axis} tickLine={false} axisLine={false} interval={1} />
              <YAxis allowDecimals={false} tick={axis} tickLine={false} axisLine={false} />
              <Tooltip contentStyle={{ background: 'var(--color-surface-raised)', border: '1px solid var(--color-border)', borderRadius: 12 }} />
              <Line type="monotone" dataKey="count" name="Completed" stroke="var(--color-accent)" strokeWidth={3} dot={{ r: 3, fill: 'var(--color-primary)' }} isAnimationActive={animate} />
            </LineChart>
          </ResponsiveContainer>
        </ChartCard>
      )}

      {careMix.length > 0 && (
        <ChartCard title="Completed care by type" description="All time" summary={careMix.map((c) => `${c.label}: ${c.count}`).join('; ')}>
          <div className="pie-row">
            <ResponsiveContainer width="50%" height={150}>
              <PieChart>
                <Pie data={careMix} dataKey="count" nameKey="label" innerRadius={38} outerRadius={62} paddingAngle={2} stroke="none" isAnimationActive={animate}>
                  {careMix.map((_, i) => (
                    <Cell key={i} fill={palette[i % palette.length]} />
                  ))}
                </Pie>
              </PieChart>
            </ResponsiveContainer>
            <ul className="legend">
              {careMix.map((c, i) => (
                <li key={c.category}>
                  <span className="legend__swatch" style={{ background: palette[i % palette.length] }} />
                  {c.label} <strong className="t-numeric">{c.count}</strong>
                </li>
              ))}
            </ul>
          </div>
        </ChartCard>
      )}

      <SectionHeader title="Your collection" />
      {byCategory.length > 0 && (
        <ChartCard title="Plants by category" description={`${plants.length} plants`} summary={byCategory.map((c) => `${c.label}: ${c.count}`).join('; ')}>
          <ResponsiveContainer width="100%" height={Math.max(120, byCategory.length * 34)}>
            <BarChart data={byCategory} layout="vertical" margin={{ top: 0, right: 16, left: 8, bottom: 0 }}>
              <XAxis type="number" hide allowDecimals={false} />
              <YAxis type="category" dataKey="label" tick={axis} tickLine={false} axisLine={false} width={110} />
              <Bar dataKey="count" radius={[0, 8, 8, 0]} barSize={18} isAnimationActive={animate}>
                {byCategory.map((_, i) => (
                  <Cell key={i} fill={palette[i % palette.length]} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </ChartCard>
      )}

      <ChartCard title="Plants added" description="Last 6 months" summary={additions.map((m) => `${m.label}: ${m.count}`).join('; ')}>
        <ResponsiveContainer width="100%" height={160}>
          <BarChart data={additions} margin={{ top: 8, right: 8, left: -24, bottom: 0 }}>
            <CartesianGrid stroke="var(--color-border)" vertical={false} />
            <XAxis dataKey="label" tick={axis} tickLine={false} axisLine={false} />
            <YAxis allowDecimals={false} tick={axis} tickLine={false} axisLine={false} />
            <Bar dataKey="count" name="Added" fill="var(--color-primary)" radius={[8, 8, 0, 0]} barSize={22} isAnimationActive={animate} />
          </BarChart>
        </ResponsiveContainer>
      </ChartCard>

      <p className="t-footnote t-secondary disclaimer">“On schedule” and progress figures describe how up to date your care tasks are. They are not botanical health measurements.</p>
    </TabScreen>
  );
}
