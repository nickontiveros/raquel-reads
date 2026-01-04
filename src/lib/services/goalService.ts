import { v4 as uuidv4 } from 'uuid';
import { db } from '@/lib/db';
import { startOfDay, startOfWeek, startOfMonth, startOfYear, endOfDay, endOfWeek, endOfMonth, endOfYear } from 'date-fns';
import type { Goal, GoalType, GoalPeriod } from '@/lib/types';

export interface CreateGoalInput {
  type: GoalType;
  target: number;
  period: GoalPeriod;
}

export interface GoalProgress {
  goal: Goal;
  current: number;
  percentage: number;
  isComplete: boolean;
}

export const goalService = {
  async getAll(): Promise<Goal[]> {
    if (!db) return [];
    return db.goals.where('active').equals(1).toArray();
  },

  async getById(id: string): Promise<Goal | undefined> {
    if (!db) return undefined;
    return db.goals.get(id);
  },

  async create(input: CreateGoalInput): Promise<Goal> {
    const goal: Goal = {
      id: uuidv4(),
      type: input.type,
      target: input.target,
      period: input.period,
      startDate: new Date(),
      active: true,
    };

    await db.goals.add(goal);
    return goal;
  },

  async update(id: string, updates: Partial<Goal>): Promise<Goal | undefined> {
    if (!db) return undefined;
    await db.goals.update(id, updates);
    return db.goals.get(id);
  },

  async delete(id: string): Promise<void> {
    if (!db) return;
    await db.goals.delete(id);
  },

  async deactivate(id: string): Promise<void> {
    if (!db) return;
    await db.goals.update(id, { active: false });
  },

  async getProgress(goal: Goal): Promise<GoalProgress> {
    if (!db) {
      return { goal, current: 0, percentage: 0, isComplete: false };
    }

    const now = new Date();
    let periodStart: Date;
    let periodEnd: Date;

    switch (goal.period) {
      case 'day':
        periodStart = startOfDay(now);
        periodEnd = endOfDay(now);
        break;
      case 'week':
        periodStart = startOfWeek(now);
        periodEnd = endOfWeek(now);
        break;
      case 'month':
        periodStart = startOfMonth(now);
        periodEnd = endOfMonth(now);
        break;
      case 'year':
        periodStart = startOfYear(now);
        periodEnd = endOfYear(now);
        break;
    }

    let current = 0;

    switch (goal.type) {
      case 'daily-reading': {
        // Count unique reading days in the period
        const sessions = await db.readingSessions
          .where('date')
          .between(periodStart, periodEnd, true, true)
          .toArray();
        const uniqueDays = new Set(
          sessions.map((s) => startOfDay(new Date(s.date)).toISOString())
        );
        current = uniqueDays.size;
        break;
      }
      case 'books-per-month': {
        // Count books completed in the period
        const books = await db.books.where('status').equals('completed').toArray();
        current = books.filter((b) => {
          if (!b.completedAt) return false;
          const completedDate = new Date(b.completedAt);
          return completedDate >= periodStart && completedDate <= periodEnd;
        }).length;
        break;
      }
      case 'pages-per-day': {
        // Sum pages read in the period
        const sessions = await db.readingSessions
          .where('date')
          .between(periodStart, periodEnd, true, true)
          .toArray();
        current = sessions.reduce((sum, s) => sum + (s.pagesRead || 0), 0);
        break;
      }
      case 'reading-streak': {
        // Current streak calculation
        const sessions = await db.readingSessions.orderBy('date').reverse().toArray();
        if (sessions.length === 0) {
          current = 0;
          break;
        }

        const uniqueDaysSet = new Set<string>();
        sessions.forEach((s) => {
          uniqueDaysSet.add(startOfDay(new Date(s.date)).toISOString());
        });
        const uniqueDays = Array.from(uniqueDaysSet)
          .map((d) => new Date(d))
          .sort((a, b) => b.getTime() - a.getTime());

        const today = startOfDay(now);
        const yesterday = new Date(today);
        yesterday.setDate(yesterday.getDate() - 1);

        const isSameDay = (d1: Date, d2: Date) =>
          d1.getFullYear() === d2.getFullYear() &&
          d1.getMonth() === d2.getMonth() &&
          d1.getDate() === d2.getDate();

        const mostRecent = uniqueDays[0];
        if (!isSameDay(mostRecent, today) && !isSameDay(mostRecent, yesterday)) {
          current = 0;
          break;
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
        current = streak;
        break;
      }
    }

    const percentage = Math.min(Math.round((current / goal.target) * 100), 100);
    const isComplete = current >= goal.target;

    return { goal, current, percentage, isComplete };
  },

  async getAllWithProgress(): Promise<GoalProgress[]> {
    const goals = await this.getAll();
    return Promise.all(goals.map((goal) => this.getProgress(goal)));
  },
};
