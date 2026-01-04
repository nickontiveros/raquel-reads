'use client';

import { useState } from 'react';
import { Calendar } from '@/components/ui/calendar';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { useReadingDaysInMonth } from '@/lib/hooks/useReadingSessions';
import { isSameDay } from 'date-fns';

interface ReadingCalendarProps {
  selectedDate: Date | undefined;
  onSelectDate: (date: Date | undefined) => void;
}

export function ReadingCalendar({ selectedDate, onSelectDate }: ReadingCalendarProps) {
  const [currentMonth, setCurrentMonth] = useState(new Date());
  const readingDays = useReadingDaysInMonth(
    currentMonth.getFullYear(),
    currentMonth.getMonth()
  );

  const modifiers = {
    reading: (date: Date) => {
      if (!readingDays) return false;
      return readingDays.some((d) => isSameDay(d, date));
    },
  };

  const modifiersStyles = {
    reading: {
      backgroundColor: 'hsl(var(--primary))',
      color: 'hsl(var(--primary-foreground))',
      borderRadius: '50%',
    },
  };

  return (
    <Card>
      <CardHeader className="pb-2">
        <CardTitle className="text-base">Calendar</CardTitle>
        <CardDescription>
          Days with reading activity are highlighted
        </CardDescription>
      </CardHeader>
      <CardContent className="flex justify-center pb-4">
        <Calendar
          mode="single"
          selected={selectedDate}
          onSelect={onSelectDate}
          onMonthChange={setCurrentMonth}
          modifiers={modifiers}
          modifiersStyles={modifiersStyles}
          className="rounded-md border"
        />
      </CardContent>
    </Card>
  );
}
