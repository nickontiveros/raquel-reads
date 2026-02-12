import Foundation
import SwiftData

@Observable
final class ReadingSessionService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    func logSession(
        book: Book? = nil,
        checkIn: DailyCheckIn? = nil,
        date: Date = Date(),
        pagesRead: Int = 0,
        startPage: Int? = nil,
        endPage: Int? = nil,
        durationMinutes: Int? = nil,
        notes: String? = nil,
        source: SessionSource = .manual
    ) -> ReadingSession {
        let session = ReadingSession(
            book: book,
            checkIn: checkIn,
            date: date,
            pagesRead: pagesRead,
            startPage: startPage,
            endPage: endPage,
            durationMinutes: durationMinutes,
            notes: notes,
            source: source
        )
        modelContext.insert(session)

        // Update book progress if we have page info
        if let book, let endPage {
            book.currentPage = endPage
            book.lastReadAt = date
            book.updatedAt = Date()
            if let totalPages = book.totalPages, totalPages > 0 {
                book.percentComplete = Double(endPage) / Double(totalPages) * 100.0
            }
        }

        save()
        return session
    }

    // MARK: - Read

    func fetchAll() -> [ReadingSession] {
        let descriptor = FetchDescriptor<ReadingSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchByDate(_ date: Date) -> [ReadingSession] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }

        let predicate = #Predicate<ReadingSession> { session in
            session.date >= start && session.date < end
        }
        let descriptor = FetchDescriptor<ReadingSession>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchByDateRange(from start: Date, to end: Date) -> [ReadingSession] {
        let startDay = start.startOfDay
        let endDay = end.startOfDay
        let predicate = #Predicate<ReadingSession> { session in
            session.date >= startDay && session.date <= endDay
        }
        let descriptor = FetchDescriptor<ReadingSession>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchByBook(_ book: Book) -> [ReadingSession] {
        let bookId = book.id
        let predicate = #Predicate<ReadingSession> { session in
            session.book?.id == bookId
        }
        let descriptor = FetchDescriptor<ReadingSession>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchRecent(limit: Int = 10) -> [ReadingSession] {
        var descriptor = FetchDescriptor<ReadingSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Stats

    func totalPagesRead() -> Int {
        let all = fetchAll()
        return all.reduce(0) { $0 + $1.pagesRead }
    }

    func totalMinutesRead() -> Int {
        let all = fetchAll()
        return all.reduce(0) { $0 + ($1.durationMinutes ?? 0) }
    }

    func pagesReadOnDate(_ date: Date) -> Int {
        fetchByDate(date).reduce(0) { $0 + $1.pagesRead }
    }

    func sessionsThisMonth() -> [ReadingSession] {
        let calendar = Calendar.current
        let now = Date()
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)
        else { return [] }
        return fetchByDateRange(from: monthStart, to: monthEnd)
    }

    // MARK: - Delete

    func delete(_ session: ReadingSession) {
        modelContext.delete(session)
        save()
    }

    // MARK: - Save

    func save() {
        try? modelContext.save()
    }
}
