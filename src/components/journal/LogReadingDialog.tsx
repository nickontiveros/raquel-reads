'use client';

import { useState, useEffect } from 'react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Plus, BookOpen } from 'lucide-react';
import { useBooks } from '@/lib/hooks/useBooks';
import { readingSessionService } from '@/lib/services/readingSessionService';
import { BookCover } from '@/components/books';
import { format } from 'date-fns';
import type { Book } from '@/lib/types';

interface LogReadingDialogProps {
  date?: Date;
  bookId?: string;
  onSessionLogged?: () => void;
  trigger?: React.ReactNode;
}

export function LogReadingDialog({ date, bookId, onSessionLogged, trigger }: LogReadingDialogProps) {
  const [open, setOpen] = useState(false);
  const [selectedBook, setSelectedBook] = useState<Book | null>(null);
  const [pagesRead, setPagesRead] = useState('');
  const [notes, setNotes] = useState('');
  const [isLogging, setIsLogging] = useState(false);
  const books = useBooks();

  const sessionDate = date || new Date();

  // If bookId is provided, pre-select that book
  useEffect(() => {
    if (bookId && books) {
      const book = books.find((b) => b.id === bookId);
      if (book) {
        setSelectedBook(book);
      }
    }
  }, [bookId, books]);

  const handleLog = async () => {
    if (!selectedBook) return;

    setIsLogging(true);
    try {
      await readingSessionService.create({
        bookId: selectedBook.id,
        date: sessionDate,
        pagesRead: pagesRead ? parseInt(pagesRead) : undefined,
        notes: notes || undefined,
        source: 'manual',
      });

      setOpen(false);
      setSelectedBook(bookId ? selectedBook : null);
      setPagesRead('');
      setNotes('');
      onSessionLogged?.();
    } catch (error) {
      console.error('Failed to log reading:', error);
    } finally {
      setIsLogging(false);
    }
  };

  const resetForm = () => {
    if (!bookId) {
      setSelectedBook(null);
    }
    setPagesRead('');
    setNotes('');
  };

  return (
    <Dialog open={open} onOpenChange={(isOpen) => {
      setOpen(isOpen);
      if (!isOpen) resetForm();
    }}>
      <DialogTrigger asChild>
        {trigger || (
          <Button size="sm">
            <Plus className="mr-2 h-4 w-4" />
            Log Reading
          </Button>
        )}
      </DialogTrigger>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Log Reading Session</DialogTitle>
          <DialogDescription>
            {format(sessionDate, 'EEEE, MMMM d, yyyy')}
          </DialogDescription>
        </DialogHeader>

        <div className="mt-4 space-y-4">
          {/* Book Selection */}
          {!selectedBook ? (
            <div>
              <label className="mb-2 block text-sm font-medium">
                Select a book
              </label>
              {books && books.length > 0 ? (
                <ScrollArea className="h-[200px] rounded-md border p-2">
                  <div className="space-y-2">
                    {books
                      .filter((b) => b.status === 'reading' || b.status === 'want-to-read')
                      .map((book) => (
                        <button
                          key={book.id}
                          onClick={() => setSelectedBook(book)}
                          className="flex w-full items-center gap-3 rounded-md p-2 text-left transition-colors hover:bg-accent"
                        >
                          <BookCover src={book.coverUrl} alt={book.title} size="sm" />
                          <div className="min-w-0 flex-1">
                            <p className="line-clamp-1 font-medium">{book.title}</p>
                            <p className="line-clamp-1 text-sm text-muted-foreground">
                              {book.author}
                            </p>
                          </div>
                        </button>
                      ))}
                  </div>
                </ScrollArea>
              ) : (
                <div className="flex flex-col items-center justify-center rounded-md border py-8 text-center">
                  <BookOpen className="mb-2 h-8 w-8 text-muted-foreground" />
                  <p className="text-sm text-muted-foreground">
                    No books in your library yet
                  </p>
                </div>
              )}
            </div>
          ) : (
            <div>
              <label className="mb-2 block text-sm font-medium">Book</label>
              <div className="flex items-center gap-3 rounded-md border p-3">
                <BookCover src={selectedBook.coverUrl} alt={selectedBook.title} size="sm" />
                <div className="min-w-0 flex-1">
                  <p className="line-clamp-1 font-medium">{selectedBook.title}</p>
                  <p className="line-clamp-1 text-sm text-muted-foreground">
                    {selectedBook.author}
                  </p>
                </div>
                {!bookId && (
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => setSelectedBook(null)}
                  >
                    Change
                  </Button>
                )}
              </div>
            </div>
          )}

          {/* Pages Read */}
          <div>
            <label htmlFor="pagesRead" className="mb-1.5 block text-sm font-medium">
              Pages read (optional)
            </label>
            <Input
              id="pagesRead"
              type="number"
              placeholder="e.g., 25"
              value={pagesRead}
              onChange={(e) => setPagesRead(e.target.value)}
            />
          </div>

          {/* Notes */}
          <div>
            <label htmlFor="notes" className="mb-1.5 block text-sm font-medium">
              Notes (optional)
            </label>
            <Input
              id="notes"
              placeholder="Any thoughts about today's reading..."
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
            />
          </div>

          {/* Submit */}
          <Button
            onClick={handleLog}
            disabled={!selectedBook || isLogging}
            className="w-full"
          >
            {isLogging ? 'Logging...' : 'Log Reading'}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
