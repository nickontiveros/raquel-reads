'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { BookOpen, Calendar, Flame, Target, Plus, RefreshCw, Loader2 } from 'lucide-react';
import { useCurrentlyReading, useCompletedBooksCount } from '@/lib/hooks/useBooks';
import { useActiveDaysCount, useCurrentStreak, useRecentReadingSessions } from '@/lib/hooks/useReadingSessions';
import { useGoalsWithProgress } from '@/lib/hooks/useGoals';
import { BookCard, AddBookDialog } from '@/components/books';
import { SessionCard, LogReadingDialog } from '@/components/journal';
import { kindleService } from '@/lib/services/kindleService';

export default function DashboardPage() {
  const currentlyReading = useCurrentlyReading();
  const completedCount = useCompletedBooksCount();
  const activeDays = useActiveDaysCount();
  const currentStreak = useCurrentStreak();
  const recentSessions = useRecentReadingSessions(5);
  const goalsWithProgress = useGoalsWithProgress();

  const [isKindleConnected, setIsKindleConnected] = useState(false);
  const [isSyncing, setIsSyncing] = useState(false);

  // Check if Kindle is connected
  useEffect(() => {
    const checkKindle = async () => {
      const creds = await kindleService.getCredentials();
      setIsKindleConnected(!!creds);
    };
    checkKindle();
  }, []);

  const handleSync = async () => {
    if (!isKindleConnected) {
      window.location.href = '/settings';
      return;
    }

    setIsSyncing(true);
    try {
      await kindleService.sync();
    } finally {
      setIsSyncing(false);
    }
  };

  // Get the first active goal for display
  const activeGoal = goalsWithProgress?.find((g) => !g.isComplete);

  return (
    <div className="container py-4 sm:py-6">
      <div className="mb-4 flex flex-col gap-3 sm:mb-6 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-xl font-bold tracking-tight sm:text-2xl">Dashboard</h1>
          <p className="text-sm text-muted-foreground sm:text-base">Track your reading journey</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm" onClick={handleSync} disabled={isSyncing} className="flex-1 sm:flex-none">
            {isSyncing ? (
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
            ) : (
              <RefreshCw className="mr-2 h-4 w-4" />
            )}
            <span className="sm:inline">{isKindleConnected ? 'Sync' : 'Kindle'}</span>
            <span className="hidden sm:inline">{isKindleConnected ? ' Kindle' : ''}</span>
          </Button>
          <AddBookDialog />
        </div>
      </div>

      {/* Stats Grid */}
      <div className="mb-6 grid grid-cols-2 gap-3 sm:mb-8 sm:gap-4 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Active Days</CardTitle>
            <Calendar className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{activeDays ?? 0}</div>
            <p className="text-xs text-muted-foreground">days of reading</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Books Completed</CardTitle>
            <BookOpen className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{completedCount ?? 0}</div>
            <p className="text-xs text-muted-foreground">books finished</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Current Streak</CardTitle>
            <Flame className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{currentStreak ?? 0}</div>
            <p className="text-xs text-muted-foreground">days in a row</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Reading Goal</CardTitle>
            <Target className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            {activeGoal ? (
              <>
                <div className="text-2xl font-bold">
                  {activeGoal.current}/{activeGoal.goal.target}
                </div>
                <p className="text-xs text-muted-foreground">{activeGoal.percentage}% complete</p>
              </>
            ) : (
              <>
                <div className="text-2xl font-bold">--</div>
                <p className="text-xs text-muted-foreground">
                  <Link href="/stats" className="underline">
                    set a goal
                  </Link>
                </p>
              </>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Currently Reading Section */}
      <div className="mb-6 sm:mb-8">
        <div className="mb-3 flex items-center justify-between sm:mb-4">
          <h2 className="text-base font-semibold sm:text-lg">Currently Reading</h2>
          <Button variant="ghost" size="sm" asChild>
            <Link href="/books?status=reading">View all</Link>
          </Button>
        </div>

        {(!currentlyReading || currentlyReading.length === 0) ? (
          <Card>
            <CardContent className="flex flex-col items-center justify-center py-10 text-center">
              <BookOpen className="mb-4 h-12 w-12 text-muted-foreground/50" />
              <CardTitle className="mb-2">No books in progress</CardTitle>
              <CardDescription className="mb-4">
                Start tracking a book to see it here
              </CardDescription>
              <AddBookDialog
                trigger={
                  <Button>
                    <Plus className="mr-2 h-4 w-4" />
                    Add your first book
                  </Button>
                }
              />
            </CardContent>
          </Card>
        ) : (
          <div className="grid gap-3 sm:gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {currentlyReading.slice(0, 3).map((book) => (
              <BookCard key={book.id} book={book} />
            ))}
          </div>
        )}
      </div>

      {/* Recent Activity Section */}
      <div>
        <div className="mb-3 flex items-center justify-between sm:mb-4">
          <h2 className="text-base font-semibold sm:text-lg">Recent Activity</h2>
          <Button variant="ghost" size="sm" asChild>
            <Link href="/journal">View journal</Link>
          </Button>
        </div>
        {(!recentSessions || recentSessions.length === 0) ? (
          <Card>
            <CardContent className="flex flex-col items-center justify-center py-10 text-center">
              <Calendar className="mb-4 h-12 w-12 text-muted-foreground/50" />
              <CardTitle className="mb-2">No recent activity</CardTitle>
              <CardDescription className="mb-4">
                Log your reading sessions to track your progress
              </CardDescription>
              <LogReadingDialog
                trigger={
                  <Button size="sm">
                    <Plus className="mr-2 h-4 w-4" />
                    Log Reading
                  </Button>
                }
              />
            </CardContent>
          </Card>
        ) : (
          <div className="space-y-3">
            {recentSessions.map((session) => (
              <SessionCard key={session.id} session={session} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
