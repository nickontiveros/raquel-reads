'use client';

import { useLiveQuery } from 'dexie-react-hooks';
import { db } from '@/lib/db';
import type { Book, BookStatus } from '@/lib/types';

export function useBooks(status?: BookStatus): Book[] | undefined {
  return useLiveQuery(
    () => {
      if (!db) return [];
      if (status) {
        return db.books.where('status').equals(status).toArray();
      }
      return db.books.orderBy('updatedAt').reverse().toArray();
    },
    [status]
  );
}

export function useBook(id: string): Book | undefined {
  return useLiveQuery(() => {
    if (!db) return undefined;
    return db.books.get(id);
  }, [id]);
}

export function useCurrentlyReading(): Book[] | undefined {
  return useLiveQuery(() => {
    if (!db) return [];
    return db.books.where('status').equals('reading').toArray();
  });
}

export function useCompletedBooksCount(): number | undefined {
  return useLiveQuery(() => {
    if (!db) return 0;
    return db.books.where('status').equals('completed').count();
  });
}

export function useBookStats() {
  return useLiveQuery(async () => {
    if (!db) return { total: 0, reading: 0, completed: 0, paused: 0, wantToRead: 0 };
    const books = await db.books.toArray();
    return {
      total: books.length,
      reading: books.filter((b) => b.status === 'reading').length,
      completed: books.filter((b) => b.status === 'completed').length,
      paused: books.filter((b) => b.status === 'paused').length,
      wantToRead: books.filter((b) => b.status === 'want-to-read').length,
    };
  });
}
