export type GoalType = 'daily-reading' | 'books-per-month' | 'books-per-year' | 'reading-streak' | 'pages-per-day';
export type GoalPeriod = 'day' | 'week' | 'month' | 'year';

export interface Goal {
  id: string;
  type: GoalType;
  target: number;
  period: GoalPeriod;
  startDate: Date;
  endDate?: Date;
  active: boolean;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface CreateGoalInput {
  type: GoalType;
  target: number;
  period: GoalPeriod;
  startDate?: Date;
  endDate?: Date;
}

export interface UpdateGoalInput {
  target?: number;
  endDate?: Date;
  active?: boolean;
}
