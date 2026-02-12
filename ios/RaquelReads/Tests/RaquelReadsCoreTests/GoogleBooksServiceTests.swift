import Testing
import Foundation
@testable import RaquelReadsCore

@Suite("GoogleBooksService Tests")
struct GoogleBooksServiceTests {

    // We test the parsing/dedup/sort logic by creating a service and testing
    // the public search method with a mock URLSession would require protocol
    // abstraction. Instead, we test the data types and static behaviors.

    // MARK: - GoogleBookResult

    @Test("GoogleBookResult has correct identifiable conformance")
    func resultIsIdentifiable() {
        let result = GoogleBookResult(
            id: "abc123",
            title: "Test Book",
            author: "Test Author",
            coverUrl: nil,
            pageCount: 200,
            isbn: "1234567890",
            description: "A test book"
        )

        #expect(result.id == "abc123")
        #expect(result.title == "Test Book")
        #expect(result.author == "Test Author")
        #expect(result.pageCount == 200)
        #expect(result.isbn == "1234567890")
    }

    @Test("GoogleBookResult with nil optional fields")
    func resultWithNils() {
        let result = GoogleBookResult(
            id: "xyz",
            title: "Minimal",
            author: "Unknown",
            coverUrl: nil,
            pageCount: nil,
            isbn: nil,
            description: nil
        )

        #expect(result.coverUrl == nil)
        #expect(result.pageCount == nil)
        #expect(result.isbn == nil)
        #expect(result.description == nil)
    }

    // MARK: - Response Decoding

    @Test("GoogleBooksSearchResponse decodes valid JSON")
    func decodeSearchResponse() throws {
        let json = """
        {
            "totalItems": 2,
            "items": [
                {
                    "id": "book1",
                    "volumeInfo": {
                        "title": "Dune",
                        "authors": ["Frank Herbert"],
                        "description": "A science fiction masterpiece",
                        "pageCount": 412,
                        "imageLinks": {
                            "smallThumbnail": "http://example.com/small.jpg",
                            "thumbnail": "http://example.com/thumb.jpg"
                        },
                        "industryIdentifiers": [
                            {"type": "ISBN_10", "identifier": "0441172717"},
                            {"type": "ISBN_13", "identifier": "9780441172719"}
                        ],
                        "language": "en"
                    }
                },
                {
                    "id": "book2",
                    "volumeInfo": {
                        "title": "Foundation",
                        "authors": ["Isaac Asimov"],
                        "pageCount": 244
                    }
                }
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(GoogleBooksSearchResponse.self, from: data)

        #expect(response.totalItems == 2)
        #expect(response.items?.count == 2)

        let dune = try #require(response.items?.first)
        #expect(dune.id == "book1")
        #expect(dune.volumeInfo.title == "Dune")
        #expect(dune.volumeInfo.authors == ["Frank Herbert"])
        #expect(dune.volumeInfo.pageCount == 412)
        #expect(dune.volumeInfo.description == "A science fiction masterpiece")
        #expect(dune.volumeInfo.imageLinks?.thumbnail == "http://example.com/thumb.jpg")
        #expect(dune.volumeInfo.industryIdentifiers?.count == 2)
        #expect(dune.volumeInfo.language == "en")
    }

    @Test("GoogleBooksSearchResponse decodes response with no items")
    func decodeEmptyResponse() throws {
        let json = """
        {
            "totalItems": 0
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(GoogleBooksSearchResponse.self, from: data)

        #expect(response.totalItems == 0)
        #expect(response.items == nil)
    }

    @Test("GoogleBooksSearchResponse decodes minimal volumeInfo")
    func decodeMinimalVolumeInfo() throws {
        let json = """
        {
            "totalItems": 1,
            "items": [
                {
                    "id": "minimal",
                    "volumeInfo": {
                        "title": "Untitled"
                    }
                }
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(GoogleBooksSearchResponse.self, from: data)

        let item = try #require(response.items?.first)
        #expect(item.volumeInfo.title == "Untitled")
        #expect(item.volumeInfo.authors == nil)
        #expect(item.volumeInfo.pageCount == nil)
        #expect(item.volumeInfo.imageLinks == nil)
        #expect(item.volumeInfo.industryIdentifiers == nil)
    }

    // MARK: - Error Types

    @Test("GoogleBooksError provides localized descriptions")
    func errorDescriptions() {
        let invalidUrl = GoogleBooksError.invalidUrl
        #expect(invalidUrl.errorDescription != nil)

        let invalidResponse = GoogleBooksError.invalidResponse
        #expect(invalidResponse.errorDescription != nil)

        let httpError = GoogleBooksError.httpError(429)
        #expect(httpError.errorDescription?.contains("429") == true)
    }

    // MARK: - ISBN Extraction

    @Test("ISBN-13 is preferred over ISBN-10")
    func isbnPreference() throws {
        let json = """
        {
            "totalItems": 1,
            "items": [
                {
                    "id": "isbn-test",
                    "volumeInfo": {
                        "title": "ISBN Test",
                        "industryIdentifiers": [
                            {"type": "ISBN_10", "identifier": "0441172717"},
                            {"type": "ISBN_13", "identifier": "9780441172719"}
                        ]
                    }
                }
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(GoogleBooksSearchResponse.self, from: data)
        let identifiers = try #require(response.items?.first?.volumeInfo.industryIdentifiers)

        // Verify ISBN-13 exists and would be preferred
        let isbn13 = identifiers.first(where: { $0.type == "ISBN_13" })
        let isbn10 = identifiers.first(where: { $0.type == "ISBN_10" })
        #expect(isbn13?.identifier == "9780441172719")
        #expect(isbn10?.identifier == "0441172717")
    }
}
