'use client';

import { useState } from 'react';
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
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { BookSearch } from './BookSearch';
import { Plus } from 'lucide-react';
import { bookService } from '@/lib/services/bookService';
import { googleBooksService, type GoogleBookResult } from '@/lib/services/googleBooksService';
import type { BookStatus } from '@/lib/types';

interface AddBookDialogProps {
  onBookAdded?: () => void;
  trigger?: React.ReactNode;
}

export function AddBookDialog({ onBookAdded, trigger }: AddBookDialogProps) {
  const [open, setOpen] = useState(false);
  const [manualTitle, setManualTitle] = useState('');
  const [manualAuthor, setManualAuthor] = useState('');
  const [manualPages, setManualPages] = useState('');
  const [isAdding, setIsAdding] = useState(false);

  const handleSelectBook = async (book: GoogleBookResult) => {
    setIsAdding(true);
    try {
      await bookService.create({
        title: book.title,
        author: book.authors.join(', '),
        coverUrl: googleBooksService.getCoverUrl(book),
        googleBooksId: book.id,
        isbn: googleBooksService.getIsbn(book),
        totalPages: book.pageCount,
        status: 'want-to-read' as BookStatus,
        source: 'manual',
      });
      setOpen(false);
      onBookAdded?.();
    } catch (error) {
      console.error('Failed to add book:', error);
    } finally {
      setIsAdding(false);
    }
  };

  const handleManualAdd = async () => {
    if (!manualTitle.trim() || !manualAuthor.trim()) return;

    setIsAdding(true);
    try {
      await bookService.create({
        title: manualTitle.trim(),
        author: manualAuthor.trim(),
        totalPages: manualPages ? parseInt(manualPages) : undefined,
        status: 'want-to-read' as BookStatus,
        source: 'manual',
      });
      setOpen(false);
      setManualTitle('');
      setManualAuthor('');
      setManualPages('');
      onBookAdded?.();
    } catch (error) {
      console.error('Failed to add book:', error);
    } finally {
      setIsAdding(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        {trigger || (
          <Button size="sm">
            <Plus className="mr-2 h-4 w-4" />
            Add Book
          </Button>
        )}
      </DialogTrigger>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle>Add a Book</DialogTitle>
          <DialogDescription>
            Search for a book or add it manually
          </DialogDescription>
        </DialogHeader>

        <Tabs defaultValue="search" className="mt-4">
          <TabsList className="grid w-full grid-cols-2">
            <TabsTrigger value="search">Search</TabsTrigger>
            <TabsTrigger value="manual">Manual</TabsTrigger>
          </TabsList>

          <TabsContent value="search" className="mt-4">
            <BookSearch onSelect={handleSelectBook} />
          </TabsContent>

          <TabsContent value="manual" className="mt-4 space-y-4">
            <div>
              <label htmlFor="title" className="mb-1.5 block text-sm font-medium">
                Title *
              </label>
              <Input
                id="title"
                placeholder="Book title"
                value={manualTitle}
                onChange={(e) => setManualTitle(e.target.value)}
              />
            </div>
            <div>
              <label htmlFor="author" className="mb-1.5 block text-sm font-medium">
                Author *
              </label>
              <Input
                id="author"
                placeholder="Author name"
                value={manualAuthor}
                onChange={(e) => setManualAuthor(e.target.value)}
              />
            </div>
            <div>
              <label htmlFor="pages" className="mb-1.5 block text-sm font-medium">
                Total Pages (optional)
              </label>
              <Input
                id="pages"
                type="number"
                placeholder="Number of pages"
                value={manualPages}
                onChange={(e) => setManualPages(e.target.value)}
              />
            </div>
            <Button
              onClick={handleManualAdd}
              disabled={!manualTitle.trim() || !manualAuthor.trim() || isAdding}
              className="w-full"
            >
              {isAdding ? 'Adding...' : 'Add Book'}
            </Button>
          </TabsContent>
        </Tabs>
      </DialogContent>
    </Dialog>
  );
}
