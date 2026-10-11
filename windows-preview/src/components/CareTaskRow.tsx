import { Check, Repeat } from 'lucide-react';
import { memo, useState } from 'react';
import type { CareTask, Plant } from '../types/models';
import { relativeDay } from '../utils/dates';
import { careStatus } from '../utils/recurrence';
import { CareIcon } from './Icons';
import { StatusBadge } from './StatusBadge';

interface Props {
  task: CareTask;
  plant?: Plant;
  now?: Date;
  onOpen(): void;
  onToggleComplete(): void;
}

export const CareTaskRow = memo(function CareTaskRow({ task, plant, now, onOpen, onToggleComplete }: Props) {
  const status = careStatus(task, now);
  const [animating, setAnimating] = useState(false);
  const when = task.isCompleted && task.completedAt ? `Completed ${relativeDay(task.completedAt, now).toLowerCase()}` : relativeDay(task.dueDate, now);
  return (
    <div className={`task-row ${task.isCompleted ? 'is-done' : ''} ${animating ? 'is-animating' : ''}`}>
      <button
        type="button"
        className="task-row__check"
        role="checkbox"
        aria-checked={task.isCompleted}
        aria-label={task.isCompleted ? `Mark ${task.title} as not done` : `Mark ${task.title} as done`}
        onClick={() => {
          setAnimating(true);
          window.setTimeout(() => setAnimating(false), 450);
          onToggleComplete();
        }}
      >
        <Check size={16} aria-hidden strokeWidth={3} />
      </button>
      <button type="button" className="task-row__body" onClick={onOpen} aria-label={`${task.title}. ${when}. Open details`}>
        <CareIcon category={task.category} />
        <span className="task-row__text">
          <span className="task-row__title">{task.title}</span>
          <span className="task-row__meta">
            {plant ? `${plant.name} · ` : ''}
            {when}
            {task.recurrenceIntervalDays ? (
              <span className="task-row__repeat">
                <Repeat size={11} aria-hidden /> every {task.recurrenceIntervalDays}d
              </span>
            ) : null}
          </span>
        </span>
        <StatusBadge status={status} />
      </button>
    </div>
  );
});
