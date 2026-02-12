import Testing
import Foundation
import SwiftData
@testable import RaquelReadsCore

@Suite("BookService Tests")
struct BookServiceTests {

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: DailyCheckIn.self, StreakRecord.self, Book.self,
                 ReadingSession.self, Goal.self, UserSettings.self,
            configurations: config
        )
        return ModelContext(container)
    }

    // MARK: - Create

    @Test("addBook creates a book with correct fields")
    func addBook() throws {
        let context = try makeContext()
        let service = BookService(modelContext: context)

        let book = service.addBook(
            title: "Dune",
            author: "Frank Herbert",
            totalPages: 412,
            status: .reading
        )

        #expect(book.title == "Dune")
        #expect(book.author == "Frank Herbert")
        #expect(book.totalPages == 412)
        #expect(book.status == .reading)
        #expect(book.source == .manual)
        #expect(book.startedAt != nil)
    }

    @Test("addBook with wantToRead status does not set startedAt")
    func addBookWantToRead() throws {
        let context = try makeContext()
        let service = BookService(modelContext: context)

        let book = service.addBook(title: "Future Read", author: "Author", status: .wantToRead)

        #expect(book.startedAt == nil)
    }

    // MARK: - Fetch

    @Test("fetchAll returns all books sorted by updatedAt")
    func fetchAll() throws {
        let context = try makeContext()
        let service = BookService(modelContext: context)

        _ = service.addBook(title: "Book A", author: "Author A")
        _ = service.addBook(title: "Book B", author: "Author B")
        _ = service.addBook(title: "Book C", author: "Author C")

        let all = service.fetchAll()
        #expect(all.count == 3)
    }

    @Test("fetchByStatus returns only books with matching status")
    func fetchByStatus() throws {
        let context = try makeContext()
        let service = BookService(modelContext: context)

        _ = service.addBook(title: "Reading Book", author: "A", status: .reading)
        _ = service.addBook(title: "Completed Book", author: "B", status: .completed)
        _ = service.addBook(title: "Another Reading", author: "C", status: .reading)

        let reading = service.fetchByStatus(.reading)
        #expect(reading.count == 2)

        let completed = service.fetchByStatus(.completed)
        #expect(completed.count == 1)
    }

    @Test("fetchCurrentlyReading returns only reading books")
    func fetchCurrentlyReading() throws {
        let context = try makeContext()
        let service = BookService(modelContext: context)

        _ = service.addBook(title: "Active", author: "A", status: .reading)
        _ = service.addBook(title: "Done", author: "B", status: .completed)

        let reading = service.fetchCurrentlyReading()
        #expect(reading.count == 1)
        #expect(reading.first?.title == "Active")
    }

    @Test("search finds books by title")
    func searchByTitle() throws {
        let context = try makeContext()
        let service = BookService(modelContext: context)

        _ = service.addBook(title: "The Great Gatsby", author: "F. Scott Fitzgerald")
        _ = service.addBook(title: "Gatsby Unbound", author: "Someone Else")
        _ = service.addBook(title: "War and Peace", author: "Leo Tolstoy")

        let results = service.search(query: "gatsby")
        #expect(results.count == 2)
    }

    @Test("search finds books by author")
    func searchByAuthor() throws {
        let context = try makeContext()
        let service = BookService(modelContext: context)

        _ = service.addBook(title: "Book One", author: "Jane Austen")
        _ = service.addBook(title: "Book Two", author: "Jane Austen")
        _ = service.addBook(title: "Book Three", author: "Charles Dickens")

        let results = service.search(query: "austen")
        #expect(results.count == 2)
    }

    // MARK: - Update Status

    @Test("updateStatus to completed sets completedAt and percentComplete")
    func updateStatusCompleted() throws {
        let context = try makeContext()
        let service = BookService(modelContext: context)

        let book = service.addBook(title: "Test", author: "Test", totalPages: 300, status: .reading)
        service.updateStatus(book, to: .completed)

        #expect(book.status == .completed)
        #expect(book.completedAt != nil)
        #expect(book.percentComplete == 100)
        #expect(book.currentPage == 300)
    }

    @Test("updateStatus to reading sets startedAt if not already set")
    func updateStatusReadingSetsStart() throws {
        let context = try makeContext()
        let service = BookService(modelContext: context)

        let book = service.addBook(title: "Test", author: "Test", status: .wantToRead)
        #expect(book.startedAt == nil)

        service.updateStatus(book, to: .reading)
        #expect(book.startedAt != nil)
    }

    // MARK: - Update Progress

    @Test("updateProgress updates page and percentage")
    func updateProgress() throws {
        let context = try makeContext()
        let service = BookService(modelContext: context)

        let book = service.addBook(title: "Test", author: "Test", totalPages: 200, status: .reading)
        service.updateProgress(book, currentPage: 100)

        #expect(book.currentPage == 100)
        #expect(book.percentComplete == 50.0)
        #expect(book.lastReadAt != nil)
    }

    @Test("updateProgress auto-completes when reaching total pages")
    func updateProgressAutoCompletes() throws {
        let context = try makeContext()
        let service = BookService(modelContext: context)

        let book = service.addBook(title: "Test", author: "Test", totalPages: 200, status: .reading)
        service.updateProgress(book, currentPage: 200)

        #expect(book.status == .completed)
        #expect(book.completedAt != nil)
    }

    @Test("updatePercentComplete sets percentage and calculates page")
    func updatePercentComplete() throws {
        let context = try makeContext()
        let service = BookService(modelContext: context)

        let book = service.addBook(title: "Test", author: "Test", totalPages: 400, status: .reading)
        service.updatePercentComplete(book, percent: 25.0)

        #expect(book.percentComplete == 25.0)
        #expect(book.currentPage == 100) // 25% of 400
    }

    // MARK: - Delete

    @Test("delete removes the book")
    func deleteBook() throws {
        let context = try makeContext()
        let service = BookService(modelContext: context)

        let book = service.addBook(title: "To Delete", author: "Author")
        #expect(service.fetchAll().count == 1)

        service.delete(book)
        #expect(service.fetchAll().count == 0)
    }

    // MARK: - Stats

    @Test("completedCount returns count of completed books")
    func completedCount() throws {
        let context = try makeContext()
        let service = BookService(modelContext: context)

        _ = service.addBook(title: "Done 1", author: "A", status: .completed)
        _ = service.addBook(title: "Done 2", author: "B", status: .completed)
        _ = service.addBook(title: "Reading", author: "C", status: .reading)

        #expect(service.completedCount() == 2)
    }

    @Test("totalPagesRead sums currentPage across all books")
    func totalPagesRead() throws {
        let context = try makeContext()
        let service = BookService(modelContext: context)

        let book1 = service.addBook(title: "A", author: "A", status: .reading)
        book1.currentPage = 100

        let book2 = service.addBook(title: "B", author: "B", status: .reading)
        book2.currentPage = 200

        service.save()

        #expect(service.totalPagesRead() == 300)
    }
}
