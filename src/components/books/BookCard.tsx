'use client';

import Link from 'next/link';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { BookCover } from './BookCover';
import { formatDistanceToNow } from 'date-fns';
import type { Book } from '@/lib/types';

interface BookCardProps {
  book: Book;
}

const statusLabels: Record<Book['status'], string> = {
  'reading': 'Reading',
  'completed': 'Completed',
  'paused': 'Paused',
  'want-to-read': 'Want to Read',
};

const statusVariants: Record<Book['status'], 'default' | 'secondary' | 'outline' | 'destructive'> = {
  'reading': 'default',
  'completed': 'secondary',
  'paused': 'outline',
  'want-to-read': 'outline',
};

export function BookCard({ book }: BookCardProps) {
  // Calculate progress from pages or use Kindle's percentComplete
  const progress = book.percentComplete
    ?? (book.totalPages && book.currentPage
      ? Math.round((book.currentPage / book.totalPages) * 100)
      : undefined);

  const hasProgress = progress !== undefined && progress > 0;
  const showProgressBar = book.status === 'reading' && hasProgress;

  return (
    <Link href={`/books/${book.id}`}>
      <Card className="group h-full overflow-hidden transition-shadow hover:shadow-lg active:shadow-md">
        <CardContent className="p-3 sm:p-4">
          <div className="flex gap-3 sm:gap-4">
            <BookCover
              src={book.coverUrl}
              alt={book.title}
              size="md"
              className="shrink-0"
            />
            <div className="flex min-w-0 flex-1 flex-col">
              <h3 className="line-clamp-2 text-sm font-semibold leading-tight group-hover:text-primary sm:text-base">
                {book.title}
              </h3>
              <p className="mt-1 line-clamp-1 text-xs text-muted-foreground sm:text-sm">
                {book.author}
              </p>
              <div className="mt-auto pt-2">
                <Badge variant={statusVariants[book.status]} className="text-xs">
                  {statusLabels[book.status]}
                </Badge>
              </div>
              {showProgressBar && (
                <div className="mt-2">
                  <div className="mb-1 flex justify-between text-xs text-muted-foreground">
                    {book.totalPages ? (
                      <span>{book.currentPage || 0} / {book.totalPages} pages</span>
                    ) : (
                      <span>Progress</span>
                    )}
                    <span>{progress}%</span>
                  </div>
                  <Progress value={progress} className="h-1.5 sm:h-1" />
                </div>
              )}
              {book.status === 'reading' && book.lastReadAt && (
                <p className="mt-1 text-xs text-muted-foreground">
                  Last read {formatDistanceToNow(new Date(book.lastReadAt), { addSuffix: true })}
                </p>
              )}
            </div>
          </div>
        </CardContent>
      </Card>
    </Link>
  );
}
