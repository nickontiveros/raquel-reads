'use client';

import Link from 'next/link';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { BookOpen, Calendar, Flame, Target, Plus, RefreshCw } from 'lucide-react';
import { useCurrentlyReading, useCompletedBooksCount } from '@/lib/hooks/useBooks';
import { useActiveDaysCount, useCurrentStreak, useRecentReadingSessions } from '@/lib/hooks/useReadingSessions';
import { BookCard, AddBookDialog } from '@/components/books';
import { SessionCard, LogReadingDialog } from '@/components/journal';

export default function DashboardPage() {
  const currentlyReading = useCurrentlyReading();
  const completedCount = useCompletedBooksCount();
  const activeDays = useActiveDaysCount();
  const currentStreak = useCurrentStreak();
  const recentSessions = useRecentReadingSessions(5);

  return (
    <div className="container py-6">
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Dashboard</h1>
          <p className="text-muted-foreground">
            Track your reading journey
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm">
            <RefreshCw className="mr-2 h-4 w-4" />
            Sync Kindle
          </Button>
          <AddBookDialog />
        </div>
      </div>

      {/* Stats Grid */}
      <div className="mb-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
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
            <div className="text-2xl font-bold">--</div>
            <p className="text-xs text-muted-foreground">set a goal to track</p>
          </CardContent>
        </Card>
      </div>

      {/* Currently Reading Section */}
      <div className="mb-8">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-semibold">Currently Reading</h2>
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
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {currentlyReading.slice(0, 3).map((book) => (
              <BookCard key={book.id} book={book} />
            ))}
          </div>
        )}
      </div>

      {/* Recent Activity Section */}
      <div>
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-semibold">Recent Activity</h2>
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
