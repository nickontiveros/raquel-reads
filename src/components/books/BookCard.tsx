'use client';

import Link from 'next/link';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { BookCover } from './BookCover';
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
  const progress = book.totalPages && book.currentPage
    ? Math.round((book.currentPage / book.totalPages) * 100)
    : 0;

  return (
    <Link href={`/books/${book.id}`}>
      <Card className="group h-full overflow-hidden transition-shadow hover:shadow-lg">
        <CardContent className="p-4">
          <div className="flex gap-4">
            <BookCover
              src={book.coverUrl}
              alt={book.title}
              size="md"
              className="shrink-0"
            />
            <div className="flex min-w-0 flex-1 flex-col">
              <h3 className="line-clamp-2 font-semibold leading-tight group-hover:text-primary">
                {book.title}
              </h3>
              <p className="mt-1 line-clamp-1 text-sm text-muted-foreground">
                {book.author}
              </p>
              <div className="mt-auto pt-2">
                <Badge variant={statusVariants[book.status]}>
                  {statusLabels[book.status]}
                </Badge>
              </div>
              {book.status === 'reading' && book.totalPages && (
                <div className="mt-2">
                  <div className="mb-1 flex justify-between text-xs text-muted-foreground">
                    <span>{book.currentPage || 0} / {book.totalPages} pages</span>
                    <span>{progress}%</span>
                  </div>
                  <Progress value={progress} className="h-1" />
                </div>
              )}
            </div>
          </div>
        </CardContent>
      </Card>
    </Link>
  );
}
