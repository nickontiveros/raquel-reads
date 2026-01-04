import { v4 as uuidv4 } from 'uuid';
import { db } from '@/lib/db';
import type { Book, BookStatus, CreateBookInput, UpdateBookInput } from '@/lib/types';

export const bookService = {
  async getAll(): Promise<Book[]> {
    return db.books.orderBy('updatedAt').reverse().toArray();
  },

  async getById(id: string): Promise<Book | undefined> {
    return db.books.get(id);
  },

  async getByStatus(status: BookStatus): Promise<Book[]> {
    return db.books.where('status').equals(status).toArray();
  },

  async getByKindleAsin(asin: string): Promise<Book | undefined> {
    return db.books.where('kindleAsin').equals(asin).first();
  },

  async getByGoogleBooksId(googleBooksId: string): Promise<Book | undefined> {
    return db.books.where('googleBooksId').equals(googleBooksId).first();
  },

  async search(query: string): Promise<Book[]> {
    const lowerQuery = query.toLowerCase();
    const allBooks = await db.books.toArray();
    return allBooks.filter(
      (book) =>
        book.title.toLowerCase().includes(lowerQuery) ||
        book.author.toLowerCase().includes(lowerQuery)
    );
  },

  async create(input: CreateBookInput): Promise<Book> {
    const now = new Date();
    const book: Book = {
      id: uuidv4(),
      title: input.title,
      author: input.author,
      coverUrl: input.coverUrl,
      isbn: input.isbn,
      googleBooksId: input.googleBooksId,
      kindleAsin: input.kindleAsin,
      totalPages: input.totalPages,
      status: input.status || 'want-to-read',
      source: input.source || 'manual',
      createdAt: now,
      updatedAt: now,
    };

    // If status is 'reading', set startedAt
    if (book.status === 'reading') {
      book.startedAt = now;
    }

    await db.books.add(book);
    return book;
  },

  async update(id: string, input: UpdateBookInput): Promise<Book | undefined> {
    const book = await db.books.get(id);
    if (!book) return undefined;

    const updates: Partial<Book> = {
      ...input,
      updatedAt: new Date(),
    };

    // Handle status changes
    if (input.status === 'reading' && book.status !== 'reading' && !book.startedAt) {
      updates.startedAt = new Date();
    }
    if (input.status === 'completed' && book.status !== 'completed') {
      updates.completedAt = new Date();
    }

    await db.books.update(id, updates);
    return db.books.get(id);
  },

  async delete(id: string): Promise<void> {
    await db.books.delete(id);
  },

  async getStats() {
    const books = await db.books.toArray();
    return {
      total: books.length,
      reading: books.filter((b) => b.status === 'reading').length,
      completed: books.filter((b) => b.status === 'completed').length,
      paused: books.filter((b) => b.status === 'paused').length,
      wantToRead: books.filter((b) => b.status === 'want-to-read').length,
    };
  },

  async getCompletedCount(): Promise<number> {
    return db.books.where('status').equals('completed').count();
  },

  async getCurrentlyReading(): Promise<Book[]> {
    return db.books.where('status').equals('reading').toArray();
  },
};
