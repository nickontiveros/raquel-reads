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
    const params = new URLSearchParams({
      q: query,
      maxResults: String(maxResults),
      printType: 'books',
      orderBy: 'relevance',
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

    // Transform the response
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
      const thumbnail = volumeInfo.imageLinks?.thumbnail || volumeInfo.imageLinks?.smallThumbnail;

      return {
        id,
        title: volumeInfo.title || 'Unknown Title',
        authors: volumeInfo.authors || ['Unknown Author'],
        description: volumeInfo.description,
        pageCount: volumeInfo.pageCount,
        publishedDate: volumeInfo.publishedDate,
        coverUrl: thumbnail?.replace('http://', 'https://').replace('&edge=curl', ''),
        isbn: volumeInfo.industryIdentifiers?.find(
          (id: { type: string }) => id.type === 'ISBN_13' || id.type === 'ISBN_10'
        )?.identifier,
      };
    });

    return NextResponse.json({ books, totalItems: data.totalItems || 0 });
  } catch (error) {
    console.error('Search error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
