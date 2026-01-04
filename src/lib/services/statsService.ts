import { db } from '@/lib/db';
import { startOfMonth, endOfMonth, startOfDay, subMonths } from 'date-fns';

export interface ReadingStats {
  activeDaysTotal: number;
  activeDaysThisMonth: number;
  completedBooksTotal: number;
  completedBooksThisMonth: number;
  currentStreak: number;
  longestStreak: number;
  totalPagesRead: number;
  pagesReadThisMonth: number;
  booksInProgress: number;
}

export interface MonthlyStats {
  month: Date;
  activeDays: number;
  booksCompleted: number;
  pagesRead: number;
}

export const statsService = {
  async getFullStats(): Promise<ReadingStats> {
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

    const now = new Date();
    const monthStart = startOfMonth(now);
    const monthEnd = endOfMonth(now);

    // Get all reading sessions
    const sessions = await db.readingSessions.toArray();
    const books = await db.books.toArray();

    // Calculate unique active days
    const allDays = new Set(
      sessions.map((s) => startOfDay(new Date(s.date)).toISOString())
    );
    const activeDaysTotal = allDays.size;

    // Active days this month
    const thisMonthSessions = sessions.filter((s) => {
      const date = new Date(s.date);
      return date >= monthStart && date <= monthEnd;
    });
    const thisMonthDays = new Set(
      thisMonthSessions.map((s) => startOfDay(new Date(s.date)).toISOString())
    );
    const activeDaysThisMonth = thisMonthDays.size;

    // Completed books
    const completedBooksTotal = books.filter((b) => b.status === 'completed').length;
    const completedBooksThisMonth = books.filter((b) => {
      if (b.status !== 'completed' || !b.completedAt) return false;
      const completedDate = new Date(b.completedAt);
      return completedDate >= monthStart && completedDate <= monthEnd;
    }).length;

    // Pages read
    const totalPagesRead = sessions.reduce((sum, s) => sum + (s.pagesRead || 0), 0);
    const pagesReadThisMonth = thisMonthSessions.reduce(
      (sum, s) => sum + (s.pagesRead || 0),
      0
    );

    // Streaks
    const currentStreak = await this.calculateCurrentStreak(sessions);
    const longestStreak = await this.calculateLongestStreak(sessions);

    // Books in progress
    const booksInProgress = books.filter((b) => b.status === 'reading').length;

    return {
      activeDaysTotal,
      activeDaysThisMonth,
      completedBooksTotal,
      completedBooksThisMonth,
      currentStreak,
      longestStreak,
      totalPagesRead,
      pagesReadThisMonth,
      booksInProgress,
    };
  },

  async calculateCurrentStreak(
    sessions?: { date: Date | string }[]
  ): Promise<number> {
    if (!db && !sessions) return 0;

    const allSessions = sessions || (await db.readingSessions.toArray());
    if (allSessions.length === 0) return 0;

    // Get unique reading days, sorted descending
    const uniqueDaysSet = new Set<string>();
    allSessions.forEach((s) => {
      uniqueDaysSet.add(startOfDay(new Date(s.date)).toISOString());
    });
    const uniqueDays = Array.from(uniqueDaysSet)
      .map((d) => new Date(d))
      .sort((a, b) => b.getTime() - a.getTime());

    if (uniqueDays.length === 0) return 0;

    const today = startOfDay(new Date());
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    const isSameDay = (d1: Date, d2: Date) =>
      d1.getFullYear() === d2.getFullYear() &&
      d1.getMonth() === d2.getMonth() &&
      d1.getDate() === d2.getDate();

    const mostRecent = uniqueDays[0];
    if (!isSameDay(mostRecent, today) && !isSameDay(mostRecent, yesterday)) {
      return 0;
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

  async calculateLongestStreak(
    sessions?: { date: Date | string }[]
  ): Promise<number> {
    if (!db && !sessions) return 0;

    const allSessions = sessions || (await db.readingSessions.toArray());
    if (allSessions.length === 0) return 0;

    // Get unique reading days, sorted ascending
    const uniqueDaysSet = new Set<string>();
    allSessions.forEach((s) => {
      uniqueDaysSet.add(startOfDay(new Date(s.date)).toISOString());
    });
    const uniqueDays = Array.from(uniqueDaysSet)
      .map((d) => new Date(d))
      .sort((a, b) => a.getTime() - b.getTime());

    if (uniqueDays.length === 0) return 0;

    const isSameDay = (d1: Date, d2: Date) =>
      d1.getFullYear() === d2.getFullYear() &&
      d1.getMonth() === d2.getMonth() &&
      d1.getDate() === d2.getDate();

    let longestStreak = 1;
    let currentStreak = 1;

    for (let i = 1; i < uniqueDays.length; i++) {
      const expectedPrev = new Date(uniqueDays[i]);
      expectedPrev.setDate(expectedPrev.getDate() - 1);

      if (isSameDay(uniqueDays[i - 1], expectedPrev)) {
        currentStreak++;
        longestStreak = Math.max(longestStreak, currentStreak);
      } else {
        currentStreak = 1;
      }
    }

    return longestStreak;
  },

  async getMonthlyStats(monthsBack: number = 6): Promise<MonthlyStats[]> {
    if (!db) return [];

    const sessions = await db.readingSessions.toArray();
    const books = await db.books.toArray();
    const stats: MonthlyStats[] = [];

    for (let i = 0; i < monthsBack; i++) {
      const monthDate = subMonths(new Date(), i);
      const monthStart = startOfMonth(monthDate);
      const monthEnd = endOfMonth(monthDate);

      const monthSessions = sessions.filter((s) => {
        const date = new Date(s.date);
        return date >= monthStart && date <= monthEnd;
      });

      const uniqueDays = new Set(
        monthSessions.map((s) => startOfDay(new Date(s.date)).toISOString())
      );

      const completedBooks = books.filter((b) => {
        if (b.status !== 'completed' || !b.completedAt) return false;
        const date = new Date(b.completedAt);
        return date >= monthStart && date <= monthEnd;
      });

      stats.push({
        month: monthStart,
        activeDays: uniqueDays.size,
        booksCompleted: completedBooks.length,
        pagesRead: monthSessions.reduce((sum, s) => sum + (s.pagesRead || 0), 0),
      });
    }

    return stats.reverse(); // Return oldest to newest
  },

  async getReadingDaysPerWeek(): Promise<{ week: string; days: number }[]> {
    if (!db) return [];

    const sessions = await db.readingSessions.toArray();
    const weekMap = new Map<string, Set<string>>();

    sessions.forEach((s) => {
      const date = new Date(s.date);
      const weekStart = new Date(date);
      weekStart.setDate(date.getDate() - date.getDay());
      const weekKey = weekStart.toISOString().split('T')[0];

      if (!weekMap.has(weekKey)) {
        weekMap.set(weekKey, new Set());
      }
      weekMap.get(weekKey)!.add(startOfDay(date).toISOString());
    });

    return Array.from(weekMap.entries())
      .map(([week, days]) => ({ week, days: days.size }))
      .sort((a, b) => a.week.localeCompare(b.week))
      .slice(-12); // Last 12 weeks
  },
};
