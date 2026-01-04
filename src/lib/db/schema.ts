import Dexie, { type Table } from 'dexie';
import type { Book, ReadingSession, Goal, UserSettings, SyncLog, KindleSnapshot } from '@/lib/types';

export class AppDatabase extends Dexie {
  books!: Table<Book, string>;
  readingSessions!: Table<ReadingSession, string>;
  goals!: Table<Goal, string>;
  userSettings!: Table<UserSettings, string>;
  syncLogs!: Table<SyncLog, string>;
  kindleSnapshots!: Table<KindleSnapshot, string>;

  constructor() {
    super('RaquelReadsDB');

    // Version 1 - initial schema
    this.version(1).stores({
      books: 'id, status, kindleAsin, googleBooksId, completedAt, createdAt',
      readingSessions: 'id, bookId, date, source, createdAt',
      goals: 'id, type, active, startDate',
      userSettings: 'id, userId',
      syncLogs: 'id, source, syncedAt',
      kindleSnapshots: 'id, snapshotAt'
    });

    // Version 2 - add updatedAt index to books
    this.version(2).stores({
      books: 'id, status, kindleAsin, googleBooksId, completedAt, createdAt, updatedAt',
      readingSessions: 'id, bookId, date, source, createdAt',
      goals: 'id, type, active, startDate',
      userSettings: 'id, userId',
      syncLogs: 'id, source, syncedAt',
      kindleSnapshots: 'id, snapshotAt'
    });
  }
}

// Only create the database instance on the client side
let db: AppDatabase;

if (typeof window !== 'undefined') {
  db = new AppDatabase();
}

export { db };
