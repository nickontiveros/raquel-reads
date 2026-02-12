import Foundation
import SwiftData

@Observable
final class BookService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    func addBook(
        title: String,
        author: String,
        coverUrl: String? = nil,
        isbn: String? = nil,
        googleBooksId: String? = nil,
        totalPages: Int? = nil,
        status: BookStatus = .wantToRead,
        source: BookSource = .manual
    ) -> Book {
        let book = Book(
            title: title,
            author: author,
            coverUrl: coverUrl,
            isbn: isbn,
            googleBooksId: googleBooksId,
            totalPages: totalPages,
            status: status,
            source: source,
            startedAt: status == .reading ? Date() : nil
        )
        modelContext.insert(book)
        save()
        return book
    }

    // MARK: - Read

    func fetchAll(sortedBy sortDescriptor: SortDescriptor<Book> = SortDescriptor(\.updatedAt, order: .reverse)) -> [Book] {
        let descriptor = FetchDescriptor<Book>(sortBy: [sortDescriptor])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchByStatus(_ status: BookStatus) -> [Book] {
        let predicate = #Predicate<Book> { $0.status == status }
        let descriptor = FetchDescriptor<Book>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchCurrentlyReading() -> [Book] {
        fetchByStatus(.reading)
    }

    func fetchCompleted() -> [Book] {
        fetchByStatus(.completed)
    }

    func fetchByGoogleBooksId(_ id: String) -> Book? {
        let predicate = #Predicate<Book> { $0.googleBooksId == id }
        let descriptor = FetchDescriptor<Book>(predicate: predicate)
        return try? modelContext.fetch(descriptor).first
    }

    func fetchByKindleAsin(_ asin: String) -> Book? {
        let predicate = #Predicate<Book> { $0.kindleAsin == asin }
        let descriptor = FetchDescriptor<Book>(predicate: predicate)
        return try? modelContext.fetch(descriptor).first
    }

    func search(query: String) -> [Book] {
        let lowered = query.lowercased()
        let predicate = #Predicate<Book> { book in
            book.title.localizedStandardContains(lowered) ||
            book.author.localizedStandardContains(lowered)
        }
        let descriptor = FetchDescriptor<Book>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func completedCount() -> Int {
        let predicate = #Predicate<Book> { $0.status == .completed }
        let descriptor = FetchDescriptor<Book>(predicate: predicate)
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    // MARK: - Update

    func updateStatus(_ book: Book, to status: BookStatus) {
        book.status = status
        book.updatedAt = Date()

        switch status {
        case .reading:
            if book.startedAt == nil {
                book.startedAt = Date()
            }
        case .completed:
            book.completedAt = Date()
            book.percentComplete = 100
            if let totalPages = book.totalPages {
                book.currentPage = totalPages
            }
        case .paused, .wantToRead:
            break
        }

        save()
    }

    func updateProgress(_ book: Book, currentPage: Int) {
        book.currentPage = currentPage
        book.lastReadAt = Date()
        book.updatedAt = Date()

        if let totalPages = book.totalPages, totalPages > 0 {
            book.percentComplete = Double(currentPage) / Double(totalPages) * 100.0
        }

        if let totalPages = book.totalPages, currentPage >= totalPages {
            updateStatus(book, to: .completed)
        }

        save()
    }

    func updatePercentComplete(_ book: Book, percent: Double) {
        book.percentComplete = min(100, max(0, percent))
        book.lastReadAt = Date()
        book.updatedAt = Date()

        if let totalPages = book.totalPages {
            book.currentPage = Int(Double(totalPages) * percent / 100.0)
        }

        if percent >= 100 {
            updateStatus(book, to: .completed)
        }

        save()
    }

    // MARK: - Delete

    func delete(_ book: Book) {
        modelContext.delete(book)
        save()
    }

    // MARK: - Stats

    func totalBooksCount() -> Int {
        let descriptor = FetchDescriptor<Book>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    func totalPagesRead() -> Int {
        let allBooks = fetchAll()
        return allBooks.reduce(0) { $0 + $1.currentPage }
    }

    // MARK: - Save

    func save() {
        try? modelContext.save()
    }
}
