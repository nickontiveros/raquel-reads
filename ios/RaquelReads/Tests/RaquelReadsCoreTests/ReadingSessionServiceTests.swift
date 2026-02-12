import Testing
import Foundation
import SwiftData
@testable import RaquelReadsCore

@Suite("ReadingSessionService Tests")
struct ReadingSessionServiceTests {

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: DailyCheckIn.self, StreakRecord.self, Book.self,
                 ReadingSession.self, Goal.self, UserSettings.self,
            configurations: config
        )
        return ModelContext(container)
    }

    private func makeBook(_ context: ModelContext, title: String = "Test Book", totalPages: Int = 300) -> Book {
        let book = Book(title: title, author: "Author", totalPages: totalPages, status: .reading)
        context.insert(book)
        try? context.save()
        return book
    }

    // MARK: - Create

    @Test("logSession creates a reading session")
    func logSessionCreates() throws {
        let context = try makeContext()
        let service = ReadingSessionService(modelContext: context)

        let session = service.logSession(pagesRead: 30)

        #expect(session.pagesRead == 30)
        #expect(session.source == .manual)
    }

    @Test("logSession with book links the session to the book")
    func logSessionWithBook() throws {
        let context = try makeContext()
        let service = ReadingSessionService(modelContext: context)
        let book = makeBook(context)

        let session = service.logSession(book: book, pagesRead: 50)

        #expect(session.book?.id == book.id)
    }

    @Test("logSession with endPage updates book progress")
    func logSessionUpdatesBookProgress() throws {
        let context = try makeContext()
        let service = ReadingSessionService(modelContext: context)
        let book = makeBook(context, totalPages: 200)

        _ = service.logSession(book: book, pagesRead: 50, startPage: 0, endPage: 100)

        #expect(book.currentPage == 100)
        #expect(book.percentComplete == 50.0)
        #expect(book.lastReadAt != nil)
    }

    @Test("logSession with notes stores notes")
    func logSessionWithNotes() throws {
        let context = try makeContext()
        let service = ReadingSessionService(modelContext: context)

        let session = service.logSession(
            pagesRead: 10,
            notes: "Really enjoyed this chapter"
        )

        #expect(session.notes == "Really enjoyed this chapter")
    }

    @Test("logSession with duration stores duration")
    func logSessionWithDuration() throws {
        let context = try makeContext()
        let service = ReadingSessionService(modelContext: context)

        let session = service.logSession(pagesRead: 20, durationMinutes: 45)

        #expect(session.durationMinutes == 45)
    }

    // MARK: - Fetch

    @Test("fetchAll returns all sessions sorted by date descending")
    func fetchAll() throws {
        let context = try makeContext()
        let service = ReadingSessionService(modelContext: context)
        let calendar = Calendar.current

        let date1 = calendar.date(byAdding: .day, value: -2, to: Date())!
        let date2 = calendar.date(byAdding: .day, value: -1, to: Date())!
        let date3 = Date()

        _ = service.logSession(date: date1, pagesRead: 10)
        _ = service.logSession(date: date2, pagesRead: 20)
        _ = service.logSession(date: date3, pagesRead: 30)

        let all = service.fetchAll()
        #expect(all.count == 3)
        // Most recent first
        #expect(all.first?.pagesRead == 30)
    }

    @Test("fetchByDate returns sessions for a specific day only")
    func fetchByDate() throws {
        let context = try makeContext()
        let service = ReadingSessionService(modelContext: context)
        let calendar = Calendar.current

        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!

        _ = service.logSession(date: yesterday, pagesRead: 10)
        _ = service.logSession(date: yesterday, pagesRead: 20)
        _ = service.logSession(date: Date(), pagesRead: 30)

        let yesterdaySessions = service.fetchByDate(yesterday)
        #expect(yesterdaySessions.count == 2)

        let todaySessions = service.fetchByDate(Date())
        #expect(todaySessions.count == 1)
    }

    @Test("fetchByDateRange returns sessions within range")
    func fetchByDateRange() throws {
        let context = try makeContext()
        let service = ReadingSessionService(modelContext: context)
        let calendar = Calendar.current

        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            _ = service.logSession(date: date, pagesRead: 10 * (i + 1))
        }

        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: Date())!
        let oneDayAgo = calendar.date(byAdding: .day, value: -1, to: Date())!

        let range = service.fetchByDateRange(from: threeDaysAgo, to: oneDayAgo)
        #expect(range.count == 3)
    }

    @Test("fetchByBook returns sessions for a specific book")
    func fetchByBook() throws {
        let context = try makeContext()
        let service = ReadingSessionService(modelContext: context)

        let book1 = makeBook(context, title: "Book 1")
        let book2 = makeBook(context, title: "Book 2")

        _ = service.logSession(book: book1, pagesRead: 10)
        _ = service.logSession(book: book1, pagesRead: 20)
        _ = service.logSession(book: book2, pagesRead: 30)

        let book1Sessions = service.fetchByBook(book1)
        #expect(book1Sessions.count == 2)

        let book2Sessions = service.fetchByBook(book2)
        #expect(book2Sessions.count == 1)
    }

    @Test("fetchRecent respects limit")
    func fetchRecent() throws {
        let context = try makeContext()
        let service = ReadingSessionService(modelContext: context)

        for i in 0..<10 {
            let calendar = Calendar.current
            let date = calendar.date(byAdding: .hour, value: -i, to: Date())!
            _ = service.logSession(date: date, pagesRead: 10)
        }

        let recent3 = service.fetchRecent(limit: 3)
        #expect(recent3.count == 3)

        let recent5 = service.fetchRecent(limit: 5)
        #expect(recent5.count == 5)
    }

    // MARK: - Stats

    @Test("totalPagesRead sums all sessions")
    func totalPagesRead() throws {
        let context = try makeContext()
        let service = ReadingSessionService(modelContext: context)

        _ = service.logSession(pagesRead: 10)
        _ = service.logSession(pagesRead: 20)
        _ = service.logSession(pagesRead: 30)

        #expect(service.totalPagesRead() == 60)
    }

    @Test("totalMinutesRead sums all durations")
    func totalMinutesRead() throws {
        let context = try makeContext()
        let service = ReadingSessionService(modelContext: context)

        _ = service.logSession(pagesRead: 10, durationMinutes: 30)
        _ = service.logSession(pagesRead: 20, durationMinutes: 45)
        _ = service.logSession(pagesRead: 30) // no duration

        #expect(service.totalMinutesRead() == 75)
    }

    @Test("pagesReadOnDate returns pages for a specific day")
    func pagesReadOnDate() throws {
        let context = try makeContext()
        let service = ReadingSessionService(modelContext: context)

        _ = service.logSession(date: Date(), pagesRead: 15)
        _ = service.logSession(date: Date(), pagesRead: 25)

        #expect(service.pagesReadOnDate(Date()) == 40)
    }

    // MARK: - Delete

    @Test("delete removes the session")
    func deleteSession() throws {
        let context = try makeContext()
        let service = ReadingSessionService(modelContext: context)

        let session = service.logSession(pagesRead: 10)
        #expect(service.fetchAll().count == 1)

        service.delete(session)
        #expect(service.fetchAll().count == 0)
    }
}
