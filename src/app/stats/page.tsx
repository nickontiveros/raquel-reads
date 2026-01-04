'use client';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import { BookOpen, Calendar, Flame, Target, TrendingUp, Plus } from 'lucide-react';

export default function StatsPage() {
  return (
    <div className="container py-6">
      <div className="mb-6">
        <h1 className="text-2xl font-bold tracking-tight">Statistics</h1>
        <p className="text-muted-foreground">
          Your reading progress and goals
        </p>
      </div>

      {/* Main Stats */}
      <div className="mb-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Active Days</CardTitle>
            <Calendar className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">0</div>
            <p className="text-xs text-muted-foreground">all time</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Books Completed</CardTitle>
            <BookOpen className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">0</div>
            <p className="text-xs text-muted-foreground">all time</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Current Streak</CardTitle>
            <Flame className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">0</div>
            <p className="text-xs text-muted-foreground">days in a row</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Longest Streak</CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">0</div>
            <p className="text-xs text-muted-foreground">personal best</p>
          </CardContent>
        </Card>
      </div>

      {/* Goals Section */}
      <div className="mb-8">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-semibold">Reading Goals</h2>
          <Button variant="outline" size="sm">
            <Plus className="mr-2 h-4 w-4" />
            Add Goal
          </Button>
        </div>
        <Card>
          <CardContent className="flex flex-col items-center justify-center py-10 text-center">
            <Target className="mb-4 h-12 w-12 text-muted-foreground/50" />
            <CardTitle className="mb-2">No goals set</CardTitle>
            <CardDescription className="mb-4 max-w-sm">
              Set reading goals to stay motivated and track your progress
            </CardDescription>
            <Button size="sm">
              <Plus className="mr-2 h-4 w-4" />
              Create a Goal
            </Button>
          </CardContent>
        </Card>
      </div>

      {/* Monthly Overview */}
      <div>
        <div className="mb-4">
          <h2 className="text-lg font-semibold">This Month</h2>
        </div>
        <div className="grid gap-4 sm:grid-cols-2">
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Reading Days</CardTitle>
              <CardDescription>Days you&apos;ve read this month</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="mb-2 flex items-baseline justify-between">
                <span className="text-2xl font-bold">0</span>
                <span className="text-sm text-muted-foreground">/ {new Date(new Date().getFullYear(), new Date().getMonth() + 1, 0).getDate()} days</span>
              </div>
              <Progress value={0} className="h-2" />
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-base">Books Finished</CardTitle>
              <CardDescription>Books completed this month</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="mb-2 flex items-baseline justify-between">
                <span className="text-2xl font-bold">0</span>
                <span className="text-sm text-muted-foreground">books</span>
              </div>
              <Progress value={0} className="h-2" />
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
