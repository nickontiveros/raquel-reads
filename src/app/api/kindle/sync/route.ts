import { NextRequest, NextResponse } from 'next/server';
import { Kindle } from 'kindle-api';

const TLS_CLIENT_API_URL = process.env.TLS_CLIENT_API_URL || 'http://localhost:8080';
const TLS_CLIENT_API_KEY = process.env.TLS_CLIENT_API_KEY || 'raquel-reads-key';

interface KindleAuthor {
  firstName?: string;
  lastName?: string;
}

interface KindleBookData {
  asin: string;
  title: string;
  authors?: KindleAuthor[];
  imageUrl?: string;
  mangaOrComicAsin?: boolean;
  originType?: string;
  productUrl?: string;
  webReaderUrl?: string;
  details?: () => Promise<unknown>;
  fullDetails?: (details: unknown) => Promise<{ percentageRead?: number }>;
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { cookies, deviceToken, tlsClientApiUrl } = body;

    if (!cookies) {
      return NextResponse.json(
        { message: 'Kindle cookies are required' },
        { status: 400 }
      );
    }

    if (!deviceToken) {
      return NextResponse.json(
        { message: 'Device token is required. Get it from Network tab when loading read.amazon.com - look for getDeviceToken request.' },
        { status: 400 }
      );
    }

    // Use custom TLS client API URL if provided, otherwise fall back to env or default
    const apiUrl = tlsClientApiUrl || TLS_CLIENT_API_URL;

    // Format cookies for the request
    const cookieString = typeof cookies === 'string'
      ? cookies
      : Object.entries(cookies).map(([k, v]) => `${k}=${v}`).join('; ');

    console.log('Initializing Kindle API with device token:', deviceToken.substring(0, 10) + '...');

    // Initialize kindle-api with our TLS server
    let kindle;
    try {
      kindle = await Kindle.fromConfig({
        cookies: cookieString,
        deviceToken: deviceToken,
        tlsServer: {
          url: apiUrl,
          apiKey: TLS_CLIENT_API_KEY,
        },
      });
    } catch (error) {
      console.error('Kindle initialization error:', error);
      const message = error instanceof Error ? error.message : 'Unknown error';

      if (message.includes('401') || message.includes('auth')) {
        return NextResponse.json(
          { message: 'Kindle authentication failed. Please check your cookies and device token are fresh.' },
          { status: 401 }
        );
      }

      return NextResponse.json(
        { message: `Failed to connect to Kindle: ${message}` },
        { status: 503 }
      );
    }

    console.log('Kindle API initialized, fetching books...');

    // Get books from the library
    const books = kindle.defaultBooks || [];
    console.log(`Found ${books.length} books in library`);

    // Log first book structure for debugging
    if (books.length > 0) {
      const sampleBook = books[0];
      console.log('Sample book structure:', JSON.stringify({
        asin: sampleBook.asin,
        title: sampleBook.title,
        authors: sampleBook.authors,
        imageUrl: sampleBook.imageUrl,
        originType: sampleBook.originType,
        hasDetails: typeof sampleBook.details === 'function',
      }, null, 2));
    }

    // Transform to our snapshot format, fetching details for each book
    const snapshot = await Promise.all(books.map(async (book) => {
      // Format authors from { firstName, lastName } objects
      let authorString = 'Unknown';
      const bookAuthors = book.authors as KindleAuthor[] | undefined;
      if (Array.isArray(bookAuthors) && bookAuthors.length > 0) {
        authorString = bookAuthors
          .map((a) => {
            const parts = [a.firstName, a.lastName].filter(Boolean);
            return parts.join(' ') || 'Unknown';
          })
          .join(', ');
      }

      // Try to get reading progress
      let percentComplete: number | undefined;
      let lastOpenedAt: Date | undefined;

      if (typeof book.details === 'function') {
        try {
          const details = await book.details();

          // Get last read date from syncDate
          const detailsObj = details as unknown as { progress?: { syncDate?: string | Date } };
          if (detailsObj?.progress?.syncDate) {
            lastOpenedAt = new Date(detailsObj.progress.syncDate);
          }

          // Call fullDetails to get percentageRead
          if (typeof book.fullDetails === 'function') {
            try {
              const fullDetails = await book.fullDetails(details) as { percentageRead?: number };

              // Log the first book's fullDetails structure
              if (book.asin === books[0]?.asin) {
                console.log('Full details response for first book:', JSON.stringify(fullDetails, null, 2));
              }

              if (fullDetails?.percentageRead !== undefined) {
                percentComplete = Math.round(fullDetails.percentageRead);
              }
            } catch (e) {
              console.log(`Could not fetch fullDetails for ${book.asin}:`, e);
            }
          }
        } catch (e) {
          console.log(`Could not fetch details for ${book.asin}:`, e);
        }
      }

      return {
        asin: book.asin,
        title: book.title,
        author: authorString,
        percentComplete,
        lastOpenedAt,
        coverUrl: book.imageUrl,
      };
    }));

    console.log('First 3 books processed:', snapshot.slice(0, 3));

    // Return the result
    return NextResponse.json({
      success: true,
      books: snapshot,
      booksAdded: 0, // Will be calculated client-side
      booksUpdated: 0,
      sessionsCreated: 0,
    });

  } catch (error) {
    console.error('Kindle sync error:', error);
    return NextResponse.json(
      { message: error instanceof Error ? error.message : 'Internal server error' },
      { status: 500 }
    );
  }
}
