export type BookStatus = 'reading' | 'completed' | 'paused' | 'want-to-read';
export type BookSource = 'manual' | 'kindle';

export interface Book {
  id: string;
  title: string;
  author: string;
  coverUrl?: string;
  isbn?: string;
  googleBooksId?: string;
  kindleAsin?: string;
  totalPages?: number;
  currentPage?: number;
  status: BookStatus;
  source: BookSource;
  startedAt?: Date;
  completedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateBookInput {
  title: string;
  author: string;
  coverUrl?: string;
  isbn?: string;
  googleBooksId?: string;
  kindleAsin?: string;
  totalPages?: number;
  status?: BookStatus;
  source?: BookSource;
}

export interface UpdateBookInput {
  title?: string;
  author?: string;
  coverUrl?: string;
  isbn?: string;
  totalPages?: number;
  currentPage?: number;
  status?: BookStatus;
  startedAt?: Date;
  completedAt?: Date;
}
