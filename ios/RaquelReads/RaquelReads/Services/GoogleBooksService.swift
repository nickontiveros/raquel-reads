import Foundation

// MARK: - Google Books API Response Types

struct GoogleBooksSearchResponse: Codable {
    let totalItems: Int
    let items: [GoogleBooksItem]?
}

struct GoogleBooksItem: Codable {
    let id: String
    let volumeInfo: GoogleBooksVolumeInfo
}

struct GoogleBooksVolumeInfo: Codable {
    let title: String
    let authors: [String]?
    let description: String?
    let pageCount: Int?
    let imageLinks: GoogleBooksImageLinks?
    let industryIdentifiers: [GoogleBooksIdentifier]?
    let language: String?
}

struct GoogleBooksImageLinks: Codable {
    let smallThumbnail: String?
    let thumbnail: String?
}

struct GoogleBooksIdentifier: Codable {
    let type: String
    let identifier: String
}

// MARK: - App-level search result

struct GoogleBookResult: Identifiable, Sendable {
    let id: String
    let title: String
    let author: String
    let coverUrl: String?
    let pageCount: Int?
    let isbn: String?
    let description: String?
}

// MARK: - Service

actor GoogleBooksService {
    private let apiKey: String?
    private let baseUrl = "https://www.googleapis.com/books/v1/volumes"
    private let session: URLSession

    init(apiKey: String? = nil, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    /// Search Google Books API for books matching a query
    func search(query: String, maxResults: Int = 20) async throws -> [GoogleBookResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        // Request extra results so we can filter and deduplicate
        let requestCount = min(maxResults * 2, 40)
        var components = URLComponents(string: baseUrl)!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "maxResults", value: String(requestCount)),
            URLQueryItem(name: "printType", value: "books"),
            URLQueryItem(name: "langRestrict", value: "en"),
        ]

        if let apiKey {
            components.queryItems?.append(URLQueryItem(name: "key", value: apiKey))
        }

        guard let url = components.url else {
            throw GoogleBooksError.invalidUrl
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleBooksError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw GoogleBooksError.httpError(httpResponse.statusCode)
        }

        let searchResponse = try JSONDecoder().decode(GoogleBooksSearchResponse.self, from: data)

        guard let items = searchResponse.items else {
            return []
        }

        // Convert, deduplicate, and quality-sort
        let results = items.compactMap { mapToResult($0) }
        let deduplicated = deduplicate(results)
        let sorted = qualitySort(deduplicated)

        return Array(sorted.prefix(maxResults))
    }

    // MARK: - Mapping

    private func mapToResult(_ item: GoogleBooksItem) -> GoogleBookResult? {
        let info = item.volumeInfo
        guard !info.title.isEmpty else { return nil }

        let author = info.authors?.joined(separator: ", ") ?? "Unknown Author"

        // Prefer thumbnail, upgrade HTTP to HTTPS
        var coverUrl = info.imageLinks?.thumbnail ?? info.imageLinks?.smallThumbnail
        if let url = coverUrl {
            coverUrl = url.replacingOccurrences(of: "http://", with: "https://")
        }

        // Extract ISBN (prefer ISBN-13)
        let isbn = info.industryIdentifiers?
            .first(where: { $0.type == "ISBN_13" })?.identifier
            ?? info.industryIdentifiers?
            .first(where: { $0.type == "ISBN_10" })?.identifier

        return GoogleBookResult(
            id: item.id,
            title: info.title,
            author: author,
            coverUrl: coverUrl,
            pageCount: info.pageCount,
            isbn: isbn,
            description: info.description
        )
    }

    // MARK: - Deduplication

    private func deduplicate(_ results: [GoogleBookResult]) -> [GoogleBookResult] {
        var seen = Set<String>()
        return results.filter { result in
            let key = "\(result.title.lowercased())|\(result.author.lowercased())"
            if seen.contains(key) {
                return false
            }
            seen.insert(key)
            return true
        }
    }

    // MARK: - Quality Sort

    /// Prioritize books with covers, page counts, and ISBNs
    private func qualitySort(_ results: [GoogleBookResult]) -> [GoogleBookResult] {
        results.sorted { a, b in
            score(a) > score(b)
        }
    }

    private func score(_ result: GoogleBookResult) -> Int {
        var s = 0
        if result.coverUrl != nil { s += 3 }
        if result.pageCount != nil { s += 2 }
        if result.isbn != nil { s += 1 }
        return s
    }
}

// MARK: - Errors

enum GoogleBooksError: Error, LocalizedError {
    case invalidUrl
    case invalidResponse
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidUrl:
            "Invalid search URL"
        case .invalidResponse:
            "Invalid response from Google Books"
        case .httpError(let code):
            "Google Books returned error \(code)"
        }
    }
}
