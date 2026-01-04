export interface GoogleBookResult {
  id: string;
  title: string;
  authors: string[];
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
}

export interface GoogleBooksApiItem {
  id: string;
  volumeInfo: {
    title: string;
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
}

export interface GoogleBooksSearchResponse {
  items?: GoogleBooksApiItem[];
  totalItems: number;
}

export const googleBooksService = {
  async search(query: string, maxResults = 10): Promise<GoogleBookResult[]> {
    const response = await fetch('/api/books/search', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ query, maxResults }),
    });

    if (!response.ok) {
      throw new Error('Failed to search books');
    }

    const data = await response.json();
    return data.books;
  },

  parseGoogleBookResult(item: GoogleBooksApiItem): GoogleBookResult {
    const { volumeInfo, id } = item;
    return {
      id,
      title: volumeInfo.title,
      authors: volumeInfo.authors || ['Unknown Author'],
      description: volumeInfo.description,
      pageCount: volumeInfo.pageCount,
      publishedDate: volumeInfo.publishedDate,
      imageLinks: volumeInfo.imageLinks,
      industryIdentifiers: volumeInfo.industryIdentifiers,
    };
  },

  getIsbn(book: GoogleBookResult): string | undefined {
    const isbn13 = book.industryIdentifiers?.find((id) => id.type === 'ISBN_13');
    const isbn10 = book.industryIdentifiers?.find((id) => id.type === 'ISBN_10');
    return isbn13?.identifier || isbn10?.identifier;
  },

  getCoverUrl(book: GoogleBookResult): string | undefined {
    // Prefer higher resolution thumbnail
    const url = book.imageLinks?.thumbnail || book.imageLinks?.smallThumbnail;
    // Convert HTTP to HTTPS and remove zoom parameter for better quality
    if (url) {
      return url.replace('http://', 'https://').replace('&edge=curl', '');
    }
    return undefined;
  },
};
