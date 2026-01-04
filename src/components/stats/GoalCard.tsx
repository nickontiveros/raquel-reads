'use client';

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import { Trash2, Target, Flame, BookOpen, Calendar, BookMarked } from 'lucide-react';
import { goalService, type GoalProgress } from '@/lib/services/goalService';
import type { GoalType, GoalPeriod } from '@/lib/types';

interface GoalCardProps {
  goalProgress: GoalProgress;
  onDelete?: () => void;
}

const goalIcons: Record<GoalType, React.ReactNode> = {
  'daily-reading': <Calendar className="h-4 w-4" />,
  'books-per-month': <BookOpen className="h-4 w-4" />,
  'books-per-year': <BookOpen className="h-4 w-4" />,
  'reading-streak': <Flame className="h-4 w-4" />,
  'pages-per-day': <BookMarked className="h-4 w-4" />,
};

const goalLabels: Record<GoalType, string> = {
  'daily-reading': 'Reading Days',
  'books-per-month': 'Books to Finish',
  'books-per-year': 'Books to Finish',
  'reading-streak': 'Reading Streak',
  'pages-per-day': 'Pages per Day',
};

const periodLabels: Record<GoalPeriod, string> = {
  day: 'today',
  week: 'this week',
  month: 'this month',
  year: 'this year',
};

export function GoalCard({ goalProgress, onDelete }: GoalCardProps) {
  const { goal, current, percentage, isComplete } = goalProgress;

  const handleDelete = async () => {
    if (confirm('Delete this goal?')) {
      await goalService.delete(goal.id);
      onDelete?.();
    }
  };

  return (
    <Card className={isComplete ? 'border-green-500/50 bg-green-50/50' : ''}>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <div className="flex items-center gap-2">
          <span className="text-muted-foreground">{goalIcons[goal.type]}</span>
          <CardTitle className="text-sm font-medium">
            {goalLabels[goal.type]}
          </CardTitle>
        </div>
        <Button
          variant="ghost"
          size="icon"
          className="h-8 w-8 text-muted-foreground hover:text-destructive"
          onClick={handleDelete}
        >
          <Trash2 className="h-4 w-4" />
        </Button>
      </CardHeader>
      <CardContent>
        <div className="mb-2 flex items-baseline justify-between">
          <span className="text-2xl font-bold">
            {current}
            <span className="text-lg text-muted-foreground">/{goal.target}</span>
          </span>
          <span className="text-sm text-muted-foreground">
            {goal.type === 'reading-streak' ? 'days' : periodLabels[goal.period]}
          </span>
        </div>
        <Progress
          value={percentage}
          className={`h-2 ${isComplete ? '[&>div]:bg-green-500' : ''}`}
        />
        {isComplete && (
          <p className="mt-2 text-sm font-medium text-green-600">
            Goal achieved!
          </p>
        )}
      </CardContent>
    </Card>
  );
}
