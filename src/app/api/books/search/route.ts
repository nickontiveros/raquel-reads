import { NextRequest, NextResponse } from 'next/server';

const GOOGLE_BOOKS_API = 'https://www.googleapis.com/books/v1/volumes';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { query, maxResults = 10 } = body;

    if (!query || typeof query !== 'string') {
      return NextResponse.json(
        { error: 'Query is required' },
        { status: 400 }
      );
    }

    const apiKey = process.env.GOOGLE_BOOKS_API_KEY;

    // Build URL with or without API key
    // Request more results than needed to allow for filtering
    const params = new URLSearchParams({
      q: query,
      maxResults: String(Math.min(maxResults * 2, 40)), // Request extra for filtering
      printType: 'books',
      orderBy: 'relevance',
      langRestrict: 'en', // Prioritize English results
    });

    if (apiKey) {
      params.set('key', apiKey);
    }

    const url = `${GOOGLE_BOOKS_API}?${params.toString()}`;

    const response = await fetch(url, {
      headers: {
        'Accept': 'application/json',
      },
    });

    if (!response.ok) {
      console.error('Google Books API error:', response.status, response.statusText);
      return NextResponse.json(
        { error: 'Failed to search Google Books' },
        { status: response.status }
      );
    }

    const data = await response.json();

    // Transform the response to match GoogleBookResult type
    const books = (data.items || []).map((item: {
      id: string;
      volumeInfo: {
        title?: string;
        authors?: string[];
        description?: string;
        pageCount?: number;
        publishedDate?: string;
        imageLinks?: {
          thumbnail?: string;
          smallThumbnail?: string;
        };
        industryIdentifiers?: Array<{
          type: string;
          identifier: string;
        }>;
      };
    }) => {
      const { volumeInfo, id } = item;

      // Transform imageLinks URLs to HTTPS
      let imageLinks = volumeInfo.imageLinks;
      if (imageLinks) {
        imageLinks = {
          thumbnail: imageLinks.thumbnail?.replace('http://', 'https://'),
          smallThumbnail: imageLinks.smallThumbnail?.replace('http://', 'https://'),
        };
      }

      return {
        id,
        title: volumeInfo.title || 'Unknown Title',
        authors: volumeInfo.authors || ['Unknown Author'],
        description: volumeInfo.description,
        pageCount: volumeInfo.pageCount,
        publishedDate: volumeInfo.publishedDate,
        imageLinks,
        industryIdentifiers: volumeInfo.industryIdentifiers,
      };
    });

    // Filter and deduplicate results
    const seen = new Set<string>();
    const filteredBooks = books
      .filter((book: { title: string; authors: string[]; pageCount?: number; imageLinks?: { thumbnail?: string } }) => {
        // Skip books without proper titles
        if (!book.title || book.title === 'Unknown Title') return false;

        // Create a key for deduplication (lowercase title + first author)
        const key = `${book.title.toLowerCase()}|${book.authors[0]?.toLowerCase() || ''}`;
        if (seen.has(key)) return false;
        seen.add(key);

        return true;
      })
      // Sort by quality indicators (has cover, has page count, has ISBN)
      .sort((a: { imageLinks?: { thumbnail?: string }; pageCount?: number; industryIdentifiers?: unknown[] },
             b: { imageLinks?: { thumbnail?: string }; pageCount?: number; industryIdentifiers?: unknown[] }) => {
        const scoreA = (a.imageLinks?.thumbnail ? 2 : 0) + (a.pageCount ? 1 : 0) + (a.industryIdentifiers?.length ? 1 : 0);
        const scoreB = (b.imageLinks?.thumbnail ? 2 : 0) + (b.pageCount ? 1 : 0) + (b.industryIdentifiers?.length ? 1 : 0);
        return scoreB - scoreA;
      })
      .slice(0, maxResults);

    return NextResponse.json({ books: filteredBooks, totalItems: data.totalItems || 0 });
  } catch (error) {
    console.error('Search error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
