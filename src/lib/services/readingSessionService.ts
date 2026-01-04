import { v4 as uuidv4 } from 'uuid';
import { db } from '@/lib/db';
import { startOfDay, endOfDay, startOfMonth, endOfMonth, eachDayOfInterval, isSameDay } from 'date-fns';
import type { ReadingSession, CreateSessionInput, UpdateSessionInput } from '@/lib/types';

export const readingSessionService = {
  async getAll(): Promise<ReadingSession[]> {
    if (!db) return [];
    return db.readingSessions.orderBy('date').reverse().toArray();
  },

  async getById(id: string): Promise<ReadingSession | undefined> {
    if (!db) return undefined;
    return db.readingSessions.get(id);
  },

  async getByBookId(bookId: string): Promise<ReadingSession[]> {
    if (!db) return [];
    return db.readingSessions.where('bookId').equals(bookId).toArray();
  },

  async getByDate(date: Date): Promise<ReadingSession[]> {
    if (!db) return [];
    const start = startOfDay(date);
    const end = endOfDay(date);
    return db.readingSessions
      .where('date')
      .between(start, end, true, true)
      .toArray();
  },

  async getByDateRange(startDate: Date, endDate: Date): Promise<ReadingSession[]> {
    if (!db) return [];
    return db.readingSessions
      .where('date')
      .between(startOfDay(startDate), endOfDay(endDate), true, true)
      .toArray();
  },

  async getByMonth(year: number, month: number): Promise<ReadingSession[]> {
    if (!db) return [];
    const start = startOfMonth(new Date(year, month));
    const end = endOfMonth(new Date(year, month));
    return db.readingSessions
      .where('date')
      .between(start, end, true, true)
      .toArray();
  },

  async getReadingDaysInMonth(year: number, month: number): Promise<Date[]> {
    const sessions = await this.getByMonth(year, month);
    const uniqueDays = new Map<string, Date>();

    sessions.forEach((session) => {
      const day = startOfDay(new Date(session.date));
      const key = day.toISOString();
      if (!uniqueDays.has(key)) {
        uniqueDays.set(key, day);
      }
    });

    return Array.from(uniqueDays.values());
  },

  async create(input: CreateSessionInput): Promise<ReadingSession> {
    if (!db) throw new Error('Database not initialized');

    const now = new Date();
    const session: ReadingSession = {
      id: uuidv4(),
      bookId: input.bookId,
      date: input.date,
      pagesRead: input.pagesRead,
      startPage: input.startPage,
      endPage: input.endPage,
      durationMinutes: input.durationMinutes,
      notes: input.notes,
      source: input.source || 'manual',
      createdAt: now,
      updatedAt: now,
    };

    await db.readingSessions.add(session);
    return session;
  },

  async update(id: string, input: UpdateSessionInput): Promise<ReadingSession | undefined> {
    if (!db) return undefined;

    const session = await db.readingSessions.get(id);
    if (!session) return undefined;

    const updates: Partial<ReadingSession> = {
      ...input,
      updatedAt: new Date(),
    };

    await db.readingSessions.update(id, updates);
    return db.readingSessions.get(id);
  },

  async delete(id: string): Promise<void> {
    if (!db) return;
    await db.readingSessions.delete(id);
  },

  async deleteByBookId(bookId: string): Promise<void> {
    if (!db) return;
    await db.readingSessions.where('bookId').equals(bookId).delete();
  },

  async getActiveDaysCount(startDate?: Date, endDate?: Date): Promise<number> {
    if (!db) return 0;

    let sessions: ReadingSession[];
    if (startDate && endDate) {
      sessions = await this.getByDateRange(startDate, endDate);
    } else {
      sessions = await db.readingSessions.toArray();
    }

    const uniqueDays = new Set(
      sessions.map((s) => startOfDay(new Date(s.date)).toISOString())
    );

    return uniqueDays.size;
  },

  async getCurrentStreak(): Promise<number> {
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
  },

  async getRecentSessions(limit: number = 5): Promise<ReadingSession[]> {
    if (!db) return [];
    return db.readingSessions.orderBy('date').reverse().limit(limit).toArray();
  },
};
