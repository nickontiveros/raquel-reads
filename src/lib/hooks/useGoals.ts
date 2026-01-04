'use client';

import { useLiveQuery } from 'dexie-react-hooks';
import { db } from '@/lib/db';
import { goalService, type GoalProgress } from '@/lib/services/goalService';
import type { Goal } from '@/lib/types';

export function useGoals(): Goal[] | undefined {
  return useLiveQuery(async () => {
    if (!db) return [];
    return goalService.getAll();
  });
}

export function useGoalsWithProgress(): GoalProgress[] | undefined {
  return useLiveQuery(async () => {
    if (!db) return [];
    return goalService.getAllWithProgress();
  });
}
