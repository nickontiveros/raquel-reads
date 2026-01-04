'use client';

import { useState } from 'react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Plus } from 'lucide-react';
import { goalService } from '@/lib/services/goalService';
import type { GoalType, GoalPeriod } from '@/lib/types';

interface AddGoalDialogProps {
  trigger?: React.ReactNode;
  onGoalAdded?: () => void;
}

const goalTypes: { value: GoalType; label: string; description: string; defaultPeriod: GoalPeriod }[] = [
  {
    value: 'daily-reading',
    label: 'Reading Days',
    description: 'Read on X days per week/month',
    defaultPeriod: 'week',
  },
  {
    value: 'books-per-month',
    label: 'Books to Finish',
    description: 'Complete X books per month/year',
    defaultPeriod: 'month',
  },
  {
    value: 'pages-per-day',
    label: 'Pages per Day',
    description: 'Read X pages each day',
    defaultPeriod: 'day',
  },
  {
    value: 'reading-streak',
    label: 'Reading Streak',
    description: 'Maintain a streak of X days',
    defaultPeriod: 'day',
  },
];

const periodLabels: Record<GoalPeriod, string> = {
  day: 'per day',
  week: 'per week',
  month: 'per month',
  year: 'per year',
};

export function AddGoalDialog({ trigger, onGoalAdded }: AddGoalDialogProps) {
  const [open, setOpen] = useState(false);
  const [selectedType, setSelectedType] = useState<GoalType | null>(null);
  const [target, setTarget] = useState('');
  const [period, setPeriod] = useState<GoalPeriod>('week');
  const [isCreating, setIsCreating] = useState(false);

  const handleSelectType = (type: GoalType) => {
    const goalType = goalTypes.find((g) => g.value === type);
    setSelectedType(type);
    setPeriod(goalType?.defaultPeriod || 'week');
  };

  const handleCreate = async () => {
    if (!selectedType || !target) return;

    setIsCreating(true);
    try {
      await goalService.create({
        type: selectedType,
        target: parseInt(target),
        period,
      });
      setOpen(false);
      resetForm();
      onGoalAdded?.();
    } catch (error) {
      console.error('Failed to create goal:', error);
    } finally {
      setIsCreating(false);
    }
  };

  const resetForm = () => {
    setSelectedType(null);
    setTarget('');
    setPeriod('week');
  };

  const selectedGoalType = goalTypes.find((g) => g.value === selectedType);

  return (
    <Dialog
      open={open}
      onOpenChange={(isOpen) => {
        setOpen(isOpen);
        if (!isOpen) resetForm();
      }}
    >
      <DialogTrigger asChild>
        {trigger || (
          <Button size="sm">
            <Plus className="mr-2 h-4 w-4" />
            Add Goal
          </Button>
        )}
      </DialogTrigger>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Create a Reading Goal</DialogTitle>
          <DialogDescription>
            Set a goal to track your reading progress
          </DialogDescription>
        </DialogHeader>

        <div className="mt-4 space-y-4">
          {!selectedType ? (
            <div className="space-y-2">
              <label className="text-sm font-medium">Choose a goal type</label>
              <div className="grid gap-2">
                {goalTypes.map((type) => (
                  <button
                    key={type.value}
                    onClick={() => handleSelectType(type.value)}
                    className="flex flex-col items-start rounded-lg border p-3 text-left transition-colors hover:bg-accent"
                  >
                    <span className="font-medium">{type.label}</span>
                    <span className="text-sm text-muted-foreground">
                      {type.description}
                    </span>
                  </button>
                ))}
              </div>
            </div>
          ) : (
            <>
              <div>
                <div className="mb-3 flex items-center justify-between">
                  <span className="font-medium">{selectedGoalType?.label}</span>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => setSelectedType(null)}
                  >
                    Change
                  </Button>
                </div>
              </div>

              <div>
                <label htmlFor="target" className="mb-1.5 block text-sm font-medium">
                  Target
                </label>
                <div className="flex gap-2">
                  <Input
                    id="target"
                    type="number"
                    placeholder="e.g., 5"
                    value={target}
                    onChange={(e) => setTarget(e.target.value)}
                    min={1}
                    className="flex-1"
                  />
                  {selectedType !== 'reading-streak' && (
                    <select
                      value={period}
                      onChange={(e) => setPeriod(e.target.value as GoalPeriod)}
                      className="rounded-md border bg-background px-3 py-2 text-sm"
                    >
                      {selectedType === 'pages-per-day' ? (
                        <option value="day">per day</option>
                      ) : (
                        <>
                          <option value="week">per week</option>
                          <option value="month">per month</option>
                          <option value="year">per year</option>
                        </>
                      )}
                    </select>
                  )}
                </div>
                {selectedType === 'reading-streak' && (
                  <p className="mt-1.5 text-sm text-muted-foreground">
                    days in a row
                  </p>
                )}
              </div>

              <Button
                onClick={handleCreate}
                disabled={!target || isCreating}
                className="w-full"
              >
                {isCreating ? 'Creating...' : 'Create Goal'}
              </Button>
            </>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
}
