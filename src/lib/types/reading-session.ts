export type SessionSource = 'manual' | 'kindle';

export interface ReadingSession {
  id: string;
  bookId: string;
  date: Date;
  pagesRead?: number;
  startPage?: number;
  endPage?: number;
  durationMinutes?: number;
  notes?: string;
  source: SessionSource;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateSessionInput {
  bookId: string;
  date: Date;
  pagesRead?: number;
  startPage?: number;
  endPage?: number;
  durationMinutes?: number;
  notes?: string;
  source?: SessionSource;
}

export interface UpdateSessionInput {
  date?: Date;
  pagesRead?: number;
  startPage?: number;
  endPage?: number;
  durationMinutes?: number;
  notes?: string;
}
