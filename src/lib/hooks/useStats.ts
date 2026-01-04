'use client';

import { useLiveQuery } from 'dexie-react-hooks';
import { db } from '@/lib/db';
import { statsService, type ReadingStats, type MonthlyStats } from '@/lib/services/statsService';

export function useStats(): ReadingStats | undefined {
  return useLiveQuery(async () => {
    if (!db) {
      return {
        activeDaysTotal: 0,
        activeDaysThisMonth: 0,
        completedBooksTotal: 0,
        completedBooksThisMonth: 0,
        currentStreak: 0,
        longestStreak: 0,
        totalPagesRead: 0,
        pagesReadThisMonth: 0,
        booksInProgress: 0,
      };
    }
    return statsService.getFullStats();
  });
}

export function useMonthlyStats(monthsBack: number = 6): MonthlyStats[] | undefined {
  return useLiveQuery(async () => {
    if (!db) return [];
    return statsService.getMonthlyStats(monthsBack);
  }, [monthsBack]);
}

export function useLongestStreak(): number | undefined {
  return useLiveQuery(async () => {
    if (!db) return 0;
    return statsService.calculateLongestStreak();
  });
}
