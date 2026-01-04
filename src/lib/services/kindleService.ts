import { db } from '@/lib/db';
import type { KindleCredentials, KindleSnapshot, KindleBookSnapshot, SyncLog } from '@/lib/types';

const SYNC_COOLDOWN_MS = 60 * 60 * 1000; // 1 hour minimum between syncs
const API_TIMEOUT_MS = 30000; // 30 second timeout

export interface SyncResult {
  success: boolean;
  booksAdded: number;
  booksUpdated: number;
  sessionsCreated: number;
  error?: string;
}

export const kindleService = {
  /**
   * Check if we can sync (respects rate limiting)
   */
  async canSync(): Promise<{ allowed: boolean; nextSyncAt?: Date }> {
    if (!db) return { allowed: false };

    const settings = await db.userSettings.get('1');
    if (!settings?.lastKindleSync) {
      return { allowed: true };
    }

    const lastSync = new Date(settings.lastKindleSync);
    const nextSyncAt = new Date(lastSync.getTime() + SYNC_COOLDOWN_MS);
    const now = new Date();

    if (now >= nextSyncAt) {
      return { allowed: true };
    }

    return { allowed: false, nextSyncAt };
  },

  /**
   * Get TLS Client API URL (custom or default)
   */
  async getTlsClientApiUrl(): Promise<string | undefined> {
    if (!db) return undefined;

    const settings = await db.userSettings.get('1');
    return settings?.tlsClientApiUrl;
  },

  /**
   * Save TLS Client API URL
   */
  async saveTlsClientApiUrl(url: string): Promise<void> {
    if (!db) return;

    const existing = await db.userSettings.get('1');
    if (existing) {
      await db.userSettings.update('1', { tlsClientApiUrl: url || undefined });
    } else {
      await db.userSettings.add({
        id: '1',
        visitorId: crypto.randomUUID(),
        tlsClientApiUrl: url || undefined,
      });
    }
  },

  /**
   * Get stored Kindle credentials
   */
  async getCredentials(): Promise<KindleCredentials | null> {
    if (!db) return null;

    const settings = await db.userSettings.get('1');
    if (!settings?.kindleCookies || !settings?.kindleDeviceToken) {
      return null;
    }

    return {
      cookies: settings.kindleCookies,
      deviceToken: settings.kindleDeviceToken,
    };
  },

  /**
   * Save Kindle credentials
   */
  async saveCredentials(credentials: KindleCredentials): Promise<void> {
    if (!db) return;

    const existing = await db.userSettings.get('1');
    if (existing) {
      await db.userSettings.update('1', {
        kindleCookies: credentials.cookies,
        kindleDeviceToken: credentials.deviceToken,
      });
    } else {
      await db.userSettings.add({
        id: '1',
        visitorId: crypto.randomUUID(),
        kindleCookies: credentials.cookies,
        kindleDeviceToken: credentials.deviceToken,
      });
    }
  },

  /**
   * Clear Kindle credentials
   */
  async clearCredentials(): Promise<void> {
    if (!db) return;

    await db.userSettings.update('1', {
      kindleCookies: undefined,
      kindleDeviceToken: undefined,
      lastKindleSync: undefined,
    });
  },

  /**
   * Perform a full Kindle sync
   */
  async sync(): Promise<SyncResult> {
    // Check rate limiting
    const { allowed, nextSyncAt } = await this.canSync();
    if (!allowed) {
      return {
        success: false,
        booksAdded: 0,
        booksUpdated: 0,
        sessionsCreated: 0,
        error: `Rate limited. Next sync available at ${nextSyncAt?.toLocaleTimeString()}`,
      };
    }

    // Get credentials
    const credentials = await this.getCredentials();
    if (!credentials) {
      return {
        success: false,
        booksAdded: 0,
        booksUpdated: 0,
        sessionsCreated: 0,
        error: 'Kindle credentials not configured',
      };
    }

    try {
      // Get custom TLS client API URL if configured
      const tlsClientApiUrl = await this.getTlsClientApiUrl();

      // Call our API route to fetch Kindle library
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), API_TIMEOUT_MS);

      const response = await fetch('/api/kindle/sync', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...credentials,
          tlsClientApiUrl,
        }),
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.message || 'Sync failed');
      }

      const result = await response.json();
      const kindleBooks: KindleBookSnapshot[] = result.books || [];

      // Get previous snapshot for delta comparison
      const previousSnapshot = await this.getPreviousSnapshot();
      const { newBooks, progressChanges } = this.detectChanges(previousSnapshot, kindleBooks);

      let booksAdded = 0;
      let booksUpdated = 0;
      let sessionsCreated = 0;

      // Add new books to the database
      for (const kindleBook of newBooks) {
        // Check if book already exists by ASIN
        const existing = await db?.books.where('kindleAsin').equals(kindleBook.asin).first();

        // Check if lastOpenedAt is valid (not epoch date 1970)
        const hasValidLastRead = kindleBook.lastOpenedAt &&
          new Date(kindleBook.lastOpenedAt).getFullYear() > 1980;

        // Determine status based on progress and whether it's been read
        let status: 'reading' | 'completed' | 'want-to-read' = 'want-to-read';
        if (kindleBook.percentComplete === 100) {
          status = 'completed';
        } else if (hasValidLastRead || (kindleBook.percentComplete && kindleBook.percentComplete > 0)) {
          status = 'reading';
        }

        if (!existing) {
          await db?.books.add({
            id: crypto.randomUUID(),
            title: kindleBook.title,
            author: kindleBook.author,
            kindleAsin: kindleBook.asin,
            coverUrl: kindleBook.coverUrl,
            percentComplete: kindleBook.percentComplete,
            lastReadAt: hasValidLastRead ? kindleBook.lastOpenedAt : undefined,
            status,
            source: 'kindle',
            createdAt: new Date(),
            updatedAt: new Date(),
          });
          booksAdded++;
        } else {
          // Update existing book with latest progress (don't overwrite manual status changes)
          const updates: Record<string, unknown> = {
            percentComplete: kindleBook.percentComplete,
            updatedAt: new Date(),
          };
          if (hasValidLastRead) {
            updates.lastReadAt = kindleBook.lastOpenedAt;
          }
          // Only update status if book was in want-to-read and now has progress
          if (existing.status === 'want-to-read' && status !== 'want-to-read') {
            updates.status = status;
          }
          await db?.books.update(existing.id, updates);
        }
      }

      // Update progress for existing books and create reading sessions
      for (const { book, previousPercent } of progressChanges) {
        const existingBook = await db?.books.where('kindleAsin').equals(book.asin).first();
        if (existingBook) {
          // Update book status if completed
          if (book.percentComplete === 100 && existingBook.status !== 'completed') {
            await db?.books.update(existingBook.id, {
              status: 'completed',
              completedAt: new Date(),
              updatedAt: new Date(),
            });
          }
          booksUpdated++;

          // Create a reading session for today if progress changed
          const today = new Date();
          today.setHours(0, 0, 0, 0);

          const existingSession = await db?.readingSessions
            .where(['bookId', 'date'])
            .equals([existingBook.id, today])
            .first();

          if (!existingSession) {
            const now = new Date();
            await db?.readingSessions.add({
              id: crypto.randomUUID(),
              bookId: existingBook.id,
              date: today,
              source: 'kindle',
              notes: `Progress: ${previousPercent}% → ${book.percentComplete}%`,
              createdAt: now,
              updatedAt: now,
            });
            sessionsCreated++;
          }
        }
      }

      // Create reading sessions from Kindle's lastOpenedAt dates
      for (const kindleBook of kindleBooks) {
        // Only process books with valid lastOpenedAt dates
        if (!kindleBook.lastOpenedAt) continue;
        const lastReadDate = new Date(kindleBook.lastOpenedAt);
        if (lastReadDate.getFullYear() <= 1980) continue;

        // Find the book in our database
        const existingBook = await db?.books.where('kindleAsin').equals(kindleBook.asin).first();
        if (!existingBook) continue;

        // Normalize date to midnight for comparison
        const sessionDate = new Date(lastReadDate);
        sessionDate.setHours(0, 0, 0, 0);

        // Check if a session already exists for this book on this date
        const existingSessions = await db?.readingSessions
          .where('bookId')
          .equals(existingBook.id)
          .toArray();

        const hasSessionOnDate = existingSessions?.some(session => {
          const existingDate = new Date(session.date);
          existingDate.setHours(0, 0, 0, 0);
          return existingDate.getTime() === sessionDate.getTime();
        });

        if (!hasSessionOnDate) {
          const now = new Date();
          await db?.readingSessions.add({
            id: crypto.randomUUID(),
            bookId: existingBook.id,
            date: sessionDate,
            source: 'kindle',
            notes: kindleBook.percentComplete
              ? `Synced from Kindle (${kindleBook.percentComplete}% complete)`
              : 'Synced from Kindle',
            createdAt: now,
            updatedAt: now,
          });
          sessionsCreated++;
        }
      }

      // Save current snapshot for future comparisons
      await this.saveSnapshot(kindleBooks);

      // Update last sync time
      await db?.userSettings.update('1', {
        lastKindleSync: new Date(),
      });

      // Log the sync
      await this.logSync({
        source: 'kindle',
        status: 'success',
        itemsAdded: booksAdded,
        itemsUpdated: booksUpdated,
        syncedAt: new Date(),
      });

      return {
        success: true,
        booksAdded,
        booksUpdated,
        sessionsCreated,
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';

      // Log the failed sync
      await this.logSync({
        source: 'kindle',
        status: 'error',
        itemsAdded: 0,
        itemsUpdated: 0,
        errorMessage,
        syncedAt: new Date(),
      });

      return {
        success: false,
        booksAdded: 0,
        booksUpdated: 0,
        sessionsCreated: 0,
        error: errorMessage,
      };
    }
  },

  /**
   * Get the last sync info
   */
  async getLastSyncInfo(): Promise<{ lastSync: Date | null; status: string | null }> {
    if (!db) return { lastSync: null, status: null };

    const settings = await db.userSettings.get('1');
    const logs = await db.syncLogs
      .where('source')
      .equals('kindle')
      .reverse()
      .sortBy('syncedAt');

    return {
      lastSync: settings?.lastKindleSync ? new Date(settings.lastKindleSync) : null,
      status: logs[0]?.status || null,
    };
  },

  /**
   * Log a sync attempt
   */
  async logSync(log: Omit<SyncLog, 'id'>): Promise<void> {
    if (!db) return;

    await db.syncLogs.add({
      id: crypto.randomUUID(),
      ...log,
    });
  },

  /**
   * Get previous snapshot for delta comparison
   */
  async getPreviousSnapshot(): Promise<KindleSnapshot | null> {
    if (!db) return null;

    const snapshots = await db.kindleSnapshots
      .orderBy('snapshotAt')
      .reverse()
      .limit(1)
      .toArray();

    return snapshots[0] || null;
  },

  /**
   * Save a new snapshot
   */
  async saveSnapshot(books: KindleBookSnapshot[]): Promise<void> {
    if (!db) return;

    await db.kindleSnapshots.add({
      id: crypto.randomUUID(),
      snapshotAt: new Date(),
      books,
    });

    // Keep only the last 10 snapshots
    const allSnapshots = await db.kindleSnapshots
      .orderBy('snapshotAt')
      .reverse()
      .toArray();

    if (allSnapshots.length > 10) {
      const toDelete = allSnapshots.slice(10);
      await Promise.all(toDelete.map((s) => db.kindleSnapshots.delete(s.id)));
    }
  },

  /**
   * Compare snapshots and detect changes
   */
  detectChanges(
    previous: KindleSnapshot | null,
    current: KindleBookSnapshot[]
  ): {
    newBooks: KindleBookSnapshot[];
    progressChanges: { book: KindleBookSnapshot; previousPercent: number }[];
    recentlyOpened: KindleBookSnapshot[];
  } {
    const newBooks: KindleBookSnapshot[] = [];
    const progressChanges: { book: KindleBookSnapshot; previousPercent: number }[] = [];
    const recentlyOpened: KindleBookSnapshot[] = [];

    if (!previous) {
      // First sync - all books are "new"
      return { newBooks: current, progressChanges: [], recentlyOpened: [] };
    }

    const previousMap = new Map(previous.books.map((b) => [b.asin, b]));

    for (const book of current) {
      const prevBook = previousMap.get(book.asin);

      if (!prevBook) {
        // New book
        newBooks.push(book);
      } else {
        // Check for progress change
        if (
          book.percentComplete !== undefined &&
          prevBook.percentComplete !== undefined &&
          book.percentComplete > prevBook.percentComplete
        ) {
          progressChanges.push({ book, previousPercent: prevBook.percentComplete });
        }

        // Check for recently opened
        if (
          book.lastOpenedAt &&
          prevBook.lastOpenedAt &&
          new Date(book.lastOpenedAt) > new Date(prevBook.lastOpenedAt)
        ) {
          recentlyOpened.push(book);
        }
      }
    }

    return { newBooks, progressChanges, recentlyOpened };
  },
};
