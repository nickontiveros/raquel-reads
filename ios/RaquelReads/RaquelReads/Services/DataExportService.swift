import Foundation
import SwiftData

// MARK: - Export/Import Format

struct ExportData: Codable {
    let version: Int
    let exportedAt: Date
    let dailyCheckIns: [ExportCheckIn]
    let books: [ExportBook]
    let readingSessions: [ExportSession]
    let goals: [ExportGoal]

    static let currentVersion = 1
}

struct ExportCheckIn: Codable {
    let id: String
    let date: Date
    let didRead: Bool
    let source: String
    let createdAt: Date
}

struct ExportBook: Codable {
    let id: String
    let title: String
    let author: String
    let coverUrl: String?
    let isbn: String?
    let googleBooksId: String?
    let kindleAsin: String?
    let totalPages: Int?
    let currentPage: Int
    let percentComplete: Double
    let status: String
    let source: String
    let startedAt: Date?
    let completedAt: Date?
    let lastReadAt: Date?
    let createdAt: Date
    let updatedAt: Date
}

struct ExportSession: Codable {
    let id: String
    let bookId: String?
    let date: Date
    let pagesRead: Int
    let startPage: Int?
    let endPage: Int?
    let durationMinutes: Int?
    let notes: String?
    let source: String
    let createdAt: Date
    let updatedAt: Date
}

struct ExportGoal: Codable {
    let id: String
    let type: String
    let target: Int
    let period: String
    let startDate: Date
    let endDate: Date?
    let active: Bool
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Service

@Observable
final class DataExportService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Export

    func exportAll() throws -> Data {
        let checkIns = fetchAllCheckIns().map { checkIn in
            ExportCheckIn(
                id: checkIn.id.uuidString,
                date: checkIn.date,
                didRead: checkIn.didRead,
                source: checkIn.source.rawValue,
                createdAt: checkIn.createdAt
            )
        }

        let books = fetchAllBooks().map { book in
            ExportBook(
                id: book.id.uuidString,
                title: book.title,
                author: book.author,
                coverUrl: book.coverUrl,
                isbn: book.isbn,
                googleBooksId: book.googleBooksId,
                kindleAsin: book.kindleAsin,
                totalPages: book.totalPages,
                currentPage: book.currentPage,
                percentComplete: book.percentComplete,
                status: book.status.rawValue,
                source: book.source.rawValue,
                startedAt: book.startedAt,
                completedAt: book.completedAt,
                lastReadAt: book.lastReadAt,
                createdAt: book.createdAt,
                updatedAt: book.updatedAt
            )
        }

        let sessions = fetchAllSessions().map { session in
            ExportSession(
                id: session.id.uuidString,
                bookId: session.book?.id.uuidString,
                date: session.date,
                pagesRead: session.pagesRead,
                startPage: session.startPage,
                endPage: session.endPage,
                durationMinutes: session.durationMinutes,
                notes: session.notes,
                source: session.source.rawValue,
                createdAt: session.createdAt,
                updatedAt: session.updatedAt
            )
        }

        let goals = fetchAllGoals().map { goal in
            ExportGoal(
                id: goal.id.uuidString,
                type: goal.type.rawValue,
                target: goal.target,
                period: goal.period.rawValue,
                startDate: goal.startDate,
                endDate: goal.endDate,
                active: goal.active,
                createdAt: goal.createdAt,
                updatedAt: goal.updatedAt
            )
        }

        let exportData = ExportData(
            version: ExportData.currentVersion,
            exportedAt: Date(),
            dailyCheckIns: checkIns,
            books: books,
            readingSessions: sessions,
            goals: goals
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(exportData)
    }

    /// Export to a temporary file URL for sharing
    func exportToFile() throws -> URL {
        let data = try exportAll()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())
        let fileName = "raquel-reads-export-\(dateString).json"

        let tempDir = FileManager.default.temporaryDirectory
        let fileUrl = tempDir.appendingPathComponent(fileName)
        try data.write(to: fileUrl)
        return fileUrl
    }

    // MARK: - Import

    func importData(from data: Data) throws -> ImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let importData = try decoder.decode(ExportData.self, from: data)

        var result = ImportResult()

        // Import check-ins (skip duplicates by date)
        for exportCheckIn in importData.dailyCheckIns {
            let date = exportCheckIn.date.startOfDay
            let predicate = #Predicate<DailyCheckIn> { $0.date == date }
            let descriptor = FetchDescriptor<DailyCheckIn>(predicate: predicate)
            let existing = (try? modelContext.fetch(descriptor)) ?? []

            if existing.isEmpty {
                let source = CheckInSource(rawValue: exportCheckIn.source) ?? .manual
                let checkIn = DailyCheckIn(
                    date: exportCheckIn.date,
                    didRead: exportCheckIn.didRead,
                    source: source,
                    celebrationShown: true,
                    createdAt: exportCheckIn.createdAt
                )
                modelContext.insert(checkIn)
                result.checkInsAdded += 1
            } else {
                result.checkInsSkipped += 1
            }
        }

        // Import books (skip duplicates by ID)
        var bookIdMap: [String: Book] = [:]
        for exportBook in importData.books {
            guard let uuid = UUID(uuidString: exportBook.id) else { continue }
            let predicate = #Predicate<Book> { $0.id == uuid }
            let descriptor = FetchDescriptor<Book>(predicate: predicate)
            let existing = (try? modelContext.fetch(descriptor)) ?? []

            if existing.isEmpty {
                let status = BookStatus(rawValue: exportBook.status) ?? .wantToRead
                let source = BookSource(rawValue: exportBook.source) ?? .manual
                let book = Book(
                    id: uuid,
                    title: exportBook.title,
                    author: exportBook.author,
                    coverUrl: exportBook.coverUrl,
                    isbn: exportBook.isbn,
                    googleBooksId: exportBook.googleBooksId,
                    kindleAsin: exportBook.kindleAsin,
                    totalPages: exportBook.totalPages,
                    currentPage: exportBook.currentPage,
                    percentComplete: exportBook.percentComplete,
                    status: status,
                    source: source,
                    startedAt: exportBook.startedAt,
                    completedAt: exportBook.completedAt,
                    lastReadAt: exportBook.lastReadAt,
                    createdAt: exportBook.createdAt,
                    updatedAt: exportBook.updatedAt
                )
                modelContext.insert(book)
                bookIdMap[exportBook.id] = book
                result.booksAdded += 1
            } else {
                bookIdMap[exportBook.id] = existing.first
                result.booksSkipped += 1
            }
        }

        // Import reading sessions (skip duplicates by ID)
        for exportSession in importData.readingSessions {
            guard let uuid = UUID(uuidString: exportSession.id) else { continue }
            let predicate = #Predicate<ReadingSession> { $0.id == uuid }
            let descriptor = FetchDescriptor<ReadingSession>(predicate: predicate)
            let existing = (try? modelContext.fetch(descriptor)) ?? []

            if existing.isEmpty {
                let book = exportSession.bookId.flatMap { bookIdMap[$0] }
                let source = SessionSource(rawValue: exportSession.source) ?? .manual
                let session = ReadingSession(
                    id: uuid,
                    book: book,
                    date: exportSession.date,
                    pagesRead: exportSession.pagesRead,
                    startPage: exportSession.startPage,
                    endPage: exportSession.endPage,
                    durationMinutes: exportSession.durationMinutes,
                    notes: exportSession.notes,
                    source: source,
                    createdAt: exportSession.createdAt,
                    updatedAt: exportSession.updatedAt
                )
                modelContext.insert(session)
                result.sessionsAdded += 1
            } else {
                result.sessionsSkipped += 1
            }
        }

        // Import goals (skip duplicates by ID)
        for exportGoal in importData.goals {
            guard let uuid = UUID(uuidString: exportGoal.id) else { continue }
            let predicate = #Predicate<Goal> { $0.id == uuid }
            let descriptor = FetchDescriptor<Goal>(predicate: predicate)
            let existing = (try? modelContext.fetch(descriptor)) ?? []

            if existing.isEmpty {
                let type = GoalType(rawValue: exportGoal.type) ?? .dailyReading
                let period = GoalPeriod(rawValue: exportGoal.period) ?? .day
                let goal = Goal(
                    id: uuid,
                    type: type,
                    target: exportGoal.target,
                    period: period,
                    startDate: exportGoal.startDate,
                    endDate: exportGoal.endDate,
                    active: exportGoal.active,
                    createdAt: exportGoal.createdAt,
                    updatedAt: exportGoal.updatedAt
                )
                modelContext.insert(goal)
                result.goalsAdded += 1
            } else {
                result.goalsSkipped += 1
            }
        }

        try? modelContext.save()
        return result
    }

    func importFromFile(url: URL) throws -> ImportResult {
        let data = try Data(contentsOf: url)
        return try importData(from: data)
    }

    // MARK: - Fetch Helpers

    private func fetchAllCheckIns() -> [DailyCheckIn] {
        let descriptor = FetchDescriptor<DailyCheckIn>(sortBy: [SortDescriptor(\.date)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchAllBooks() -> [Book] {
        let descriptor = FetchDescriptor<Book>(sortBy: [SortDescriptor(\.createdAt)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchAllSessions() -> [ReadingSession] {
        let descriptor = FetchDescriptor<ReadingSession>(sortBy: [SortDescriptor(\.date)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchAllGoals() -> [Goal] {
        let descriptor = FetchDescriptor<Goal>(sortBy: [SortDescriptor(\.createdAt)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}

// MARK: - Import Result

struct ImportResult {
    var checkInsAdded = 0
    var checkInsSkipped = 0
    var booksAdded = 0
    var booksSkipped = 0
    var sessionsAdded = 0
    var sessionsSkipped = 0
    var goalsAdded = 0
    var goalsSkipped = 0

    var totalAdded: Int {
        checkInsAdded + booksAdded + sessionsAdded + goalsAdded
    }

    var totalSkipped: Int {
        checkInsSkipped + booksSkipped + sessionsSkipped + goalsSkipped
    }

    var summary: String {
        var parts: [String] = []
        if checkInsAdded > 0 { parts.append("\(checkInsAdded) check-ins") }
        if booksAdded > 0 { parts.append("\(booksAdded) books") }
        if sessionsAdded > 0 { parts.append("\(sessionsAdded) sessions") }
        if goalsAdded > 0 { parts.append("\(goalsAdded) goals") }

        if parts.isEmpty {
            return "No new data to import — everything was already up to date."
        }
        return "Imported \(parts.joined(separator: ", "))."
    }
}
