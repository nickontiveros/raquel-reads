'use client';

import { use } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Separator } from '@/components/ui/separator';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { ArrowLeft, MoreVertical, Play, Pause, CheckCircle, Trash2, BookOpen, Plus, Calendar } from 'lucide-react';
import { useBook } from '@/lib/hooks/useBooks';
import { useReadingSessionsByBookId } from '@/lib/hooks/useReadingSessions';
import { bookService } from '@/lib/services/bookService';
import { BookCover, MarkCompleteDialog } from '@/components/books';
import { LogReadingDialog, SessionCard } from '@/components/journal';
import type { BookStatus } from '@/lib/types';

const statusLabels: Record<BookStatus, string> = {
  'reading': 'Currently Reading',
  'completed': 'Completed',
  'paused': 'Paused',
  'want-to-read': 'Want to Read',
};

const statusVariants: Record<BookStatus, 'default' | 'secondary' | 'outline'> = {
  'reading': 'default',
  'completed': 'secondary',
  'paused': 'outline',
  'want-to-read': 'outline',
};

export default function BookDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const book = useBook(id);
  const sessions = useReadingSessionsByBookId(id);
  const router = useRouter();

  if (!book) {
    return (
      <div className="container py-6">
        <div className="flex flex-col items-center justify-center py-16 text-center">
          <BookOpen className="mb-4 h-16 w-16 text-muted-foreground/50" />
          <h1 className="mb-2 text-xl font-semibold">Book not found</h1>
          <p className="mb-4 text-muted-foreground">This book may have been deleted</p>
          <Button asChild>
            <Link href="/books">Back to Books</Link>
          </Button>
        </div>
      </div>
    );
  }

  const progress = book.totalPages && book.currentPage
    ? Math.round((book.currentPage / book.totalPages) * 100)
    : 0;

  const handleStatusChange = async (newStatus: BookStatus) => {
    await bookService.update(book.id, { status: newStatus });
  };

  const handleDelete = async () => {
    if (confirm('Are you sure you want to delete this book?')) {
      await bookService.delete(book.id);
      router.push('/books');
    }
  };

  const hasSessions = sessions && sessions.length > 0;

  return (
    <div className="container py-4 sm:py-6">
      {/* Header */}
      <div className="mb-4 flex items-center justify-between sm:mb-6">
        <Button variant="ghost" size="sm" asChild>
          <Link href="/books">
            <ArrowLeft className="mr-2 h-4 w-4" />
            Back
          </Link>
        </Button>
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="icon">
              <MoreVertical className="h-4 w-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuItem onClick={() => handleStatusChange('reading')}>
              <Play className="mr-2 h-4 w-4" />
              Start Reading
            </DropdownMenuItem>
            <DropdownMenuItem onClick={() => handleStatusChange('paused')}>
              <Pause className="mr-2 h-4 w-4" />
              Pause
            </DropdownMenuItem>
            <MarkCompleteDialog
              bookId={book.id}
              bookTitle={book.title}
              trigger={
                <DropdownMenuItem onSelect={(e) => e.preventDefault()}>
                  <CheckCircle className="mr-2 h-4 w-4" />
                  Mark Complete
                </DropdownMenuItem>
              }
            />
            <DropdownMenuSeparator />
            <DropdownMenuItem onClick={handleDelete} className="text-destructive">
              <Trash2 className="mr-2 h-4 w-4" />
              Delete Book
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>

      {/* Book Info */}
      <div className="grid gap-4 sm:gap-6 md:grid-cols-[200px_1fr]">
        <div className="flex justify-center md:justify-start">
          <BookCover src={book.coverUrl} alt={book.title} size="lg" />
        </div>

        <div>
          <Badge variant={statusVariants[book.status]} className="mb-2 sm:mb-3">
            {statusLabels[book.status]}
          </Badge>
          <h1 className="mb-1 text-xl font-bold sm:mb-2 sm:text-2xl">{book.title}</h1>
          <p className="mb-3 text-base text-muted-foreground sm:mb-4 sm:text-lg">{book.author}</p>

          {book.totalPages && (
            <p className="mb-4 text-sm text-muted-foreground">
              {book.totalPages} pages
            </p>
          )}

          {/* Progress */}
          {book.status === 'reading' && book.totalPages && (
            <Card className="mb-4">
              <CardHeader className="pb-2">
                <CardTitle className="text-sm">Reading Progress</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="mb-2 flex justify-between text-sm">
                  <span>Page {book.currentPage || 0} of {book.totalPages}</span>
                  <span>{progress}%</span>
                </div>
                <Progress value={progress} className="h-2" />
              </CardContent>
            </Card>
          )}

          {/* Quick Actions */}
          <div className="flex flex-wrap gap-2">
            {book.status === 'want-to-read' && (
              <Button onClick={() => handleStatusChange('reading')}>
                <Play className="mr-2 h-4 w-4" />
                Start Reading
              </Button>
            )}
            {book.status === 'reading' && (
              <>
                <LogReadingDialog
                  bookId={book.id}
                  trigger={
                    <Button>
                      <Plus className="mr-2 h-4 w-4" />
                      Log Reading
                    </Button>
                  }
                />
                <MarkCompleteDialog
                  bookId={book.id}
                  bookTitle={book.title}
                  trigger={
                    <Button variant="outline">
                      <CheckCircle className="mr-2 h-4 w-4" />
                      Mark Complete
                    </Button>
                  }
                />
              </>
            )}
            {book.status === 'paused' && (
              <Button onClick={() => handleStatusChange('reading')}>
                <Play className="mr-2 h-4 w-4" />
                Resume Reading
              </Button>
            )}
            {book.status === 'completed' && (
              <LogReadingDialog
                bookId={book.id}
                trigger={
                  <Button variant="outline">
                    <Plus className="mr-2 h-4 w-4" />
                    Log Reading
                  </Button>
                }
              />
            )}
          </div>
        </div>
      </div>

      <Separator className="my-4 sm:my-6" />

      {/* Reading Sessions */}
      <Card className="mb-4 sm:mb-6">
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="text-base">Reading Sessions</CardTitle>
              <CardDescription>
                {hasSessions
                  ? `${sessions.length} session${sessions.length !== 1 ? 's' : ''} logged`
                  : 'No sessions logged yet'}
              </CardDescription>
            </div>
            <LogReadingDialog
              bookId={book.id}
              trigger={
                <Button variant="outline" size="sm">
                  <Plus className="mr-2 h-4 w-4" />
                  Add
                </Button>
              }
            />
          </div>
        </CardHeader>
        <CardContent>
          {!hasSessions ? (
            <div className="flex flex-col items-center justify-center py-8 text-center">
              <Calendar className="mb-4 h-10 w-10 text-muted-foreground/50" />
              <p className="mb-2 text-sm font-medium">No reading sessions</p>
              <p className="mb-4 text-sm text-muted-foreground">
                Log your reading to track progress
              </p>
              <LogReadingDialog
                bookId={book.id}
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
              {sessions
                .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
                .slice(0, 5)
                .map((session) => (
                  <SessionCard key={session.id} session={session} showBook={false} />
                ))}
              {sessions.length > 5 && (
                <p className="text-center text-sm text-muted-foreground">
                  And {sessions.length - 5} more sessions...
                </p>
              )}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Details */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Details</CardTitle>
        </CardHeader>
        <CardContent className="grid gap-4 text-sm sm:grid-cols-2">
          {book.isbn && (
            <div>
              <span className="text-muted-foreground">ISBN:</span>{' '}
              <span className="font-medium">{book.isbn}</span>
            </div>
          )}
          <div>
            <span className="text-muted-foreground">Source:</span>{' '}
            <span className="font-medium capitalize">{book.source}</span>
          </div>
          {book.startedAt && (
            <div>
              <span className="text-muted-foreground">Started:</span>{' '}
              <span className="font-medium">
                {new Date(book.startedAt).toLocaleDateString()}
              </span>
            </div>
          )}
          {book.completedAt && (
            <div>
              <span className="text-muted-foreground">Completed:</span>{' '}
              <span className="font-medium">
                {new Date(book.completedAt).toLocaleDateString()}
              </span>
            </div>
          )}
          <div>
            <span className="text-muted-foreground">Added:</span>{' '}
            <span className="font-medium">
              {new Date(book.createdAt).toLocaleDateString()}
            </span>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
