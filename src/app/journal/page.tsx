'use client';

import { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Calendar as CalendarIcon, Plus } from 'lucide-react';
import { format } from 'date-fns';
import { ReadingCalendar, LogReadingDialog, SessionCard } from '@/components/journal';
import { useReadingSessionsByDate } from '@/lib/hooks/useReadingSessions';

export default function JournalPage() {
  const [selectedDate, setSelectedDate] = useState<Date | undefined>(new Date());
  const sessions = useReadingSessionsByDate(selectedDate || new Date());

  const formattedDate = selectedDate
    ? format(selectedDate, 'EEEE, MMMM d, yyyy')
    : 'Select a date';

  const hasSessions = sessions && sessions.length > 0;

  return (
    <div className="container py-4 sm:py-6">
      <div className="mb-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-xl font-bold tracking-tight sm:text-2xl">Reading Journal</h1>
          <p className="text-sm text-muted-foreground sm:text-base">
            Track your daily reading activity
          </p>
        </div>
        <LogReadingDialog date={selectedDate} />
      </div>

      <div className="grid gap-6 lg:grid-cols-[350px_1fr]">
        {/* Calendar */}
        <ReadingCalendar
          selectedDate={selectedDate}
          onSelectDate={setSelectedDate}
        />

        {/* Selected Day Details */}
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle className="text-base">{formattedDate}</CardTitle>
                <CardDescription>
                  {hasSessions
                    ? `${sessions.length} reading session${sessions.length !== 1 ? 's' : ''}`
                    : 'No reading sessions'}
                </CardDescription>
              </div>
              {selectedDate && (
                <LogReadingDialog
                  date={selectedDate}
                  trigger={
                    <Button variant="outline" size="sm">
                      <Plus className="mr-2 h-4 w-4" />
                      Add
                    </Button>
                  }
                />
              )}
            </div>
          </CardHeader>
          <CardContent>
            {!hasSessions ? (
              <div className="flex flex-col items-center justify-center py-10 text-center">
                <CalendarIcon className="mb-4 h-12 w-12 text-muted-foreground/50" />
                <p className="mb-2 font-medium">No reading logged</p>
                <p className="mb-4 text-sm text-muted-foreground">
                  Log a reading session for this day
                </p>
                <LogReadingDialog
                  date={selectedDate}
                  trigger={
                    <Button size="sm">
                      <Plus className="mr-2 h-4 w-4" />
                      Log Reading
                    </Button>
                  }
                />
              </div>
            ) : (
              <div className="space-y-3">
                {sessions.map((session) => (
                  <SessionCard key={session.id} session={session} />
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
