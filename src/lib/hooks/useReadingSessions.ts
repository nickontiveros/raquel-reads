'use client';

import { useLiveQuery } from 'dexie-react-hooks';
import { db } from '@/lib/db';
import { startOfDay, endOfDay, startOfMonth, endOfMonth } from 'date-fns';
import type { ReadingSession } from '@/lib/types';

export function useReadingSessions(): ReadingSession[] | undefined {
  return useLiveQuery(() => {
    if (!db) return [];
    return db.readingSessions.orderBy('date').reverse().toArray();
  });
}

export function useReadingSessionsByDate(date: Date): ReadingSession[] | undefined {
  return useLiveQuery(() => {
    if (!db) return [];
    const start = startOfDay(date);
    const end = endOfDay(date);
    return db.readingSessions
      .where('date')
      .between(start, end, true, true)
      .toArray();
  }, [date.toISOString()]);
}

export function useReadingSessionsByMonth(year: number, month: number): ReadingSession[] | undefined {
  return useLiveQuery(() => {
    if (!db) return [];
    const start = startOfMonth(new Date(year, month));
    const end = endOfMonth(new Date(year, month));
    return db.readingSessions
      .where('date')
      .between(start, end, true, true)
      .toArray();
  }, [year, month]);
}

export function useReadingSessionsByBookId(bookId: string): ReadingSession[] | undefined {
  return useLiveQuery(() => {
    if (!db) return [];
    return db.readingSessions.where('bookId').equals(bookId).toArray();
  }, [bookId]);
}

export function useRecentReadingSessions(limit: number = 5): ReadingSession[] | undefined {
  return useLiveQuery(() => {
    if (!db) return [];
    return db.readingSessions.orderBy('date').reverse().limit(limit).toArray();
  }, [limit]);
}

export function useReadingDaysInMonth(year: number, month: number): Date[] | undefined {
  const sessions = useReadingSessionsByMonth(year, month);

  if (!sessions) return undefined;

  const uniqueDays = new Map<string, Date>();
  sessions.forEach((session) => {
    const day = startOfDay(new Date(session.date));
    const key = day.toISOString();
    if (!uniqueDays.has(key)) {
      uniqueDays.set(key, day);
    }
  });

  return Array.from(uniqueDays.values());
}

export function useActiveDaysCount(): number | undefined {
  return useLiveQuery(async () => {
    if (!db) return 0;
    const sessions = await db.readingSessions.toArray();
    const uniqueDays = new Set(
      sessions.map((s) => startOfDay(new Date(s.date)).toISOString())
    );
    return uniqueDays.size;
  });
}

export function useCurrentStreak(): number | undefined {
  return useLiveQuery(async () => {
    if (!db) return 0;

    const sessions = await db.readingSessions.orderBy('date').reverse().toArray();
    if (sessions.length === 0) return 0;

    // Get unique reading days, sorted descending
    const uniqueDaysSet = new Set<string>();
    sessions.forEach((s) => {
      uniqueDaysSet.add(startOfDay(new Date(s.date)).toISOString());
    });
    const uniqueDays = Array.from(uniqueDaysSet)
      .map((d) => new Date(d))
      .sort((a, b) => b.getTime() - a.getTime());

    if (uniqueDays.length === 0) return 0;

    const today = startOfDay(new Date());
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    // Check if the most recent reading day is today or yesterday
    const mostRecent = uniqueDays[0];
    const isSameDay = (d1: Date, d2: Date) =>
      d1.getFullYear() === d2.getFullYear() &&
      d1.getMonth() === d2.getMonth() &&
      d1.getDate() === d2.getDate();

    if (!isSameDay(mostRecent, today) && !isSameDay(mostRecent, yesterday)) {
      return 0; // Streak is broken
    }

    let streak = 1;
    let currentDate = mostRecent;

    for (let i = 1; i < uniqueDays.length; i++) {
      const prevDate = new Date(currentDate);
      prevDate.setDate(prevDate.getDate() - 1);

      if (isSameDay(uniqueDays[i], prevDate)) {
        streak++;
        currentDate = uniqueDays[i];
      } else {
        break;
      }
    }

    return streak;
  });
}
