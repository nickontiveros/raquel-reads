'use client';

import { useState, useCallback } from 'react';
import { Search, Loader2 } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { ScrollArea } from '@/components/ui/scroll-area';
import { BookCover } from './BookCover';
import { googleBooksService, type GoogleBookResult } from '@/lib/services/googleBooksService';
import { useDebouncedCallback } from '@/lib/hooks/useDebounce';

interface BookSearchProps {
  onSelect: (book: GoogleBookResult) => void;
}

export function BookSearch({ onSelect }: BookSearchProps) {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<GoogleBookResult[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [hasSearched, setHasSearched] = useState(false);

  const searchBooks = useCallback(async (searchQuery: string) => {
    if (!searchQuery.trim()) {
      setResults([]);
      setHasSearched(false);
      return;
    }

    setIsLoading(true);
    try {
      const books = await googleBooksService.search(searchQuery);
      setResults(books);
      setHasSearched(true);
    } catch (error) {
      console.error('Search failed:', error);
      setResults([]);
    } finally {
      setIsLoading(false);
    }
  }, []);

  const debouncedSearch = useDebouncedCallback(searchBooks, 300);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setQuery(value);
    debouncedSearch(value);
  };

  return (
    <div className="space-y-4">
      <div className="relative">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          placeholder="Search for books..."
          value={query}
          onChange={handleInputChange}
          className="pl-9"
        />
        {isLoading && (
          <Loader2 className="absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 animate-spin text-muted-foreground" />
        )}
      </div>

      {hasSearched && (
        <ScrollArea className="h-[300px]">
          {results.length === 0 ? (
            <p className="py-4 text-center text-sm text-muted-foreground">
              No books found. Try a different search.
            </p>
          ) : (
            <div className="space-y-2">
              {results.map((book) => (
                <Card
                  key={book.id}
                  className="cursor-pointer transition-colors hover:bg-accent"
                  onClick={() => onSelect(book)}
                >
                  <CardContent className="flex gap-3 p-3">
                    <BookCover
                      src={googleBooksService.getCoverUrl(book)}
                      alt={book.title}
                      size="sm"
                    />
                    <div className="min-w-0 flex-1">
                      <h4 className="line-clamp-1 font-medium">{book.title}</h4>
                      <p className="line-clamp-1 text-sm text-muted-foreground">
                        {book.authors.join(', ')}
                      </p>
                      {book.pageCount && (
                        <p className="text-xs text-muted-foreground">
                          {book.pageCount} pages
                        </p>
                      )}
                    </div>
                    <Button variant="ghost" size="sm" className="shrink-0">
                      Add
                    </Button>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </ScrollArea>
      )}
    </div>
  );
}
