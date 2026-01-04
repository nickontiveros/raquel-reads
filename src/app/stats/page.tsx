'use client';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { BookOpen, Calendar, Flame, Target, TrendingUp, Plus, BookMarked } from 'lucide-react';
import { useStats, useMonthlyStats } from '@/lib/hooks/useStats';
import { useGoalsWithProgress } from '@/lib/hooks/useGoals';
import { AddGoalDialog, GoalCard } from '@/components/stats';
import { format } from 'date-fns';

export default function StatsPage() {
  const stats = useStats();
  const monthlyStats = useMonthlyStats(6);
  const goalsWithProgress = useGoalsWithProgress();

  const daysInMonth = new Date(
    new Date().getFullYear(),
    new Date().getMonth() + 1,
    0
  ).getDate();

  const monthProgress = stats
    ? Math.round((stats.activeDaysThisMonth / daysInMonth) * 100)
    : 0;

  return (
    <div className="container py-4 sm:py-6">
      <div className="mb-4 sm:mb-6">
        <h1 className="text-xl font-bold tracking-tight sm:text-2xl">Statistics</h1>
        <p className="text-sm text-muted-foreground sm:text-base">Your reading progress and goals</p>
      </div>

      {/* Main Stats */}
      <div className="mb-6 grid grid-cols-2 gap-3 sm:mb-8 sm:gap-4 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Active Days</CardTitle>
            <Calendar className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats?.activeDaysTotal ?? 0}</div>
            <p className="text-xs text-muted-foreground">all time</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Books Completed</CardTitle>
            <BookOpen className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats?.completedBooksTotal ?? 0}</div>
            <p className="text-xs text-muted-foreground">all time</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Current Streak</CardTitle>
            <Flame className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats?.currentStreak ?? 0}</div>
            <p className="text-xs text-muted-foreground">days in a row</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Longest Streak</CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats?.longestStreak ?? 0}</div>
            <p className="text-xs text-muted-foreground">personal best</p>
          </CardContent>
        </Card>
      </div>

      {/* Additional Stats */}
      <div className="mb-6 grid gap-3 sm:mb-8 sm:grid-cols-3 sm:gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Pages Read</CardTitle>
            <BookMarked className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {stats?.totalPagesRead?.toLocaleString() ?? 0}
            </div>
            <p className="text-xs text-muted-foreground">
              {stats?.pagesReadThisMonth ?? 0} this month
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Currently Reading</CardTitle>
            <BookOpen className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats?.booksInProgress ?? 0}</div>
            <p className="text-xs text-muted-foreground">books in progress</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">This Month</CardTitle>
            <Calendar className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats?.activeDaysThisMonth ?? 0}</div>
            <p className="text-xs text-muted-foreground">
              of {daysInMonth} days ({monthProgress}%)
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Goals Section */}
      <div className="mb-8">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-semibold">Reading Goals</h2>
          <AddGoalDialog />
        </div>
        {goalsWithProgress && goalsWithProgress.length > 0 ? (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {goalsWithProgress.map((gp) => (
              <GoalCard key={gp.goal.id} goalProgress={gp} />
            ))}
          </div>
        ) : (
          <Card>
            <CardContent className="flex flex-col items-center justify-center py-10 text-center">
              <Target className="mb-4 h-12 w-12 text-muted-foreground/50" />
              <CardTitle className="mb-2">No goals set</CardTitle>
              <CardDescription className="mb-4 max-w-sm">
                Set reading goals to stay motivated and track your progress
              </CardDescription>
              <AddGoalDialog />
            </CardContent>
          </Card>
        )}
      </div>

      {/* Monthly Overview */}
      <div>
        <div className="mb-4">
          <h2 className="text-lg font-semibold">Monthly History</h2>
        </div>
        {monthlyStats && monthlyStats.length > 0 ? (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {monthlyStats.slice().reverse().map((month) => (
              <Card key={month.month.toISOString()}>
                <CardHeader className="pb-2">
                  <CardTitle className="text-base">
                    {format(month.month, 'MMMM yyyy')}
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-2 text-sm">
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Active Days</span>
                      <span className="font-medium">{month.activeDays}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Books Finished</span>
                      <span className="font-medium">{month.booksCompleted}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Pages Read</span>
                      <span className="font-medium">{month.pagesRead.toLocaleString()}</span>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        ) : (
          <Card>
            <CardContent className="flex flex-col items-center justify-center py-10 text-center">
              <Calendar className="mb-4 h-12 w-12 text-muted-foreground/50" />
              <CardTitle className="mb-2">No reading history yet</CardTitle>
              <CardDescription>
                Start logging your reading sessions to see your monthly progress
              </CardDescription>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  );
}
