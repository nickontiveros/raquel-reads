export type SyncStatus = 'success' | 'error' | 'partial';
export type SyncSource = 'kindle' | 'google-books';

export interface SyncLog {
  id: string;
  source: SyncSource;
  status: SyncStatus;
  itemsAdded: number;
  itemsUpdated: number;
  errorMessage?: string;
  syncedAt: Date;
}

export interface KindleBookSnapshot {
  asin: string;
  title: string;
  author: string;
  percentComplete?: number;
  lastOpenedAt?: Date;
}

export interface KindleSnapshot {
  id: string;
  snapshotAt: Date;
  books: KindleBookSnapshot[];
}

export interface KindleCredentials {
  cookies: string;
  deviceToken: string;
}

export interface SyncResult {
  success: boolean;
  booksAdded: number;
  booksUpdated: number;
  sessionsCreated: number;
  errors: string[];
}
