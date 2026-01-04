'use client';

import { useState, useMemo } from 'react';
import { Card, CardContent, CardDescription, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { BookOpen, Plus, Search, RefreshCw } from 'lucide-react';
import { useBooks } from '@/lib/hooks/useBooks';
import { BookCard, BookCardSkeleton, AddBookDialog } from '@/components/books';
import type { BookStatus } from '@/lib/types';

type FilterValue = 'all' | BookStatus;

export default function BooksPage() {
  const [filter, setFilter] = useState<FilterValue>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const books = useBooks();

  const filteredBooks = useMemo(() => {
    if (!books) return [];

    let result = books;

    // Apply status filter
    if (filter !== 'all') {
      result = result.filter((book) => book.status === filter);
    }

    // Apply search filter
    if (searchQuery.trim()) {
      const query = searchQuery.toLowerCase();
      result = result.filter(
        (book) =>
          book.title.toLowerCase().includes(query) ||
          book.author.toLowerCase().includes(query)
      );
    }

    return result;
  }, [books, filter, searchQuery]);

  const isLoading = books === undefined;
  const isEmpty = books !== undefined && books.length === 0;
  const noResults = books && books.length > 0 && filteredBooks.length === 0;

  return (
    <div className="container py-4 sm:py-6">
      <div className="mb-4 flex items-center justify-between sm:mb-6">
        <div>
          <h1 className="text-xl font-bold tracking-tight sm:text-2xl">Books</h1>
          <p className="text-sm text-muted-foreground sm:text-base">
            {books ? `${books.length} book${books.length !== 1 ? 's' : ''} in library` : 'Loading...'}
          </p>
        </div>
        <AddBookDialog />
      </div>

      {/* Search and Filters */}
      <div className="mb-4 flex flex-col gap-3 sm:mb-6 sm:flex-row sm:items-center sm:gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Search books..."
            className="pl-9"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>
        <Tabs value={filter} onValueChange={(v) => setFilter(v as FilterValue)} className="w-full sm:w-auto">
          <TabsList className="grid w-full grid-cols-4 sm:w-auto">
            <TabsTrigger value="all">All</TabsTrigger>
            <TabsTrigger value="reading">Reading</TabsTrigger>
            <TabsTrigger value="completed">Done</TabsTrigger>
            <TabsTrigger value="want-to-read">Want</TabsTrigger>
          </TabsList>
        </Tabs>
      </div>

      {/* Loading State */}
      {isLoading && (
        <div className="grid gap-3 sm:gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {[...Array(6)].map((_, i) => (
            <BookCardSkeleton key={i} />
          ))}
        </div>
      )}

      {/* Empty State */}
      {!isLoading && isEmpty && (
        <Card>
          <CardContent className="flex flex-col items-center justify-center py-16 text-center">
            <BookOpen className="mb-4 h-16 w-16 text-muted-foreground/50" />
            <CardTitle className="mb-2">Your library is empty</CardTitle>
            <CardDescription className="mb-6 max-w-sm">
              Add books manually or sync with your Kindle library to get started
            </CardDescription>
            <div className="flex gap-2">
              <Button variant="outline">
                <RefreshCw className="mr-2 h-4 w-4" />
                Sync Kindle
              </Button>
              <AddBookDialog
                trigger={
                  <Button>
                    <Plus className="mr-2 h-4 w-4" />
                    Add Book
                  </Button>
                }
              />
            </div>
          </CardContent>
        </Card>
      )}

      {/* No Results State */}
      {!isLoading && noResults && (
        <Card>
          <CardContent className="flex flex-col items-center justify-center py-16 text-center">
            <Search className="mb-4 h-16 w-16 text-muted-foreground/50" />
            <CardTitle className="mb-2">No books found</CardTitle>
            <CardDescription>
              Try a different search or filter
            </CardDescription>
          </CardContent>
        </Card>
      )}

      {/* Book Grid */}
      {!isLoading && filteredBooks.length > 0 && (
        <div className="grid gap-3 sm:gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {filteredBooks.map((book) => (
            <BookCard key={book.id} book={book} />
          ))}
        </div>
      )}
    </div>
  );
}
