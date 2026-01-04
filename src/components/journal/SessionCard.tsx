'use client';

import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { BookCover } from '@/components/books';
import { Trash2 } from 'lucide-react';
import { useBook } from '@/lib/hooks/useBooks';
import { readingSessionService } from '@/lib/services/readingSessionService';
import type { ReadingSession } from '@/lib/types';

interface SessionCardProps {
  session: ReadingSession;
  showBook?: boolean;
  onDelete?: () => void;
}

export function SessionCard({ session, showBook = true, onDelete }: SessionCardProps) {
  const book = useBook(session.bookId);

  const handleDelete = async () => {
    if (confirm('Delete this reading session?')) {
      await readingSessionService.delete(session.id);
      onDelete?.();
    }
  };

  return (
    <Card>
      <CardContent className="flex items-start gap-3 p-4">
        {showBook && book && (
          <BookCover src={book.coverUrl} alt={book.title} size="sm" />
        )}
        <div className="min-w-0 flex-1">
          {showBook && book && (
            <>
              <h4 className="line-clamp-1 font-medium">{book.title}</h4>
              <p className="line-clamp-1 text-sm text-muted-foreground">
                {book.author}
              </p>
            </>
          )}
          <div className="mt-1 flex flex-wrap gap-x-4 gap-y-1 text-sm text-muted-foreground">
            {session.pagesRead && (
              <span>{session.pagesRead} pages</span>
            )}
            {session.durationMinutes && (
              <span>{session.durationMinutes} min</span>
            )}
          </div>
          {session.notes && (
            <p className="mt-2 text-sm text-muted-foreground">{session.notes}</p>
          )}
        </div>
        <Button
          variant="ghost"
          size="icon"
          className="shrink-0 text-muted-foreground hover:text-destructive"
          onClick={handleDelete}
        >
          <Trash2 className="h-4 w-4" />
        </Button>
      </CardContent>
    </Card>
  );
}
