import Testing
import Foundation
import SwiftData
@testable import RaquelReadsCore

@Suite("DataExportService Tests")
struct DataExportServiceTests {

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: DailyCheckIn.self, StreakRecord.self, Book.self,
                 ReadingSession.self, Goal.self, UserSettings.self,
            configurations: config
        )
        return ModelContext(container)
    }

    // MARK: - Export

    @Test("Export produces valid JSON with correct version")
    func exportProducesValidJson() throws {
        let context = try makeContext()
        let service = DataExportService(modelContext: context)

        let data = try service.exportAll()
        let decoded = try JSONDecoder.iso8601Decoder.decode(ExportData.self, from: data)

        #expect(decoded.version == ExportData.currentVersion)
        #expect(decoded.dailyCheckIns.isEmpty)
        #expect(decoded.books.isEmpty)
        #expect(decoded.readingSessions.isEmpty)
        #expect(decoded.goals.isEmpty)
    }

    @Test("Export includes all data types")
    func exportIncludesAllData() throws {
        let context = try makeContext()

        // Add sample data
        let checkIn = DailyCheckIn(date: Date(), didRead: true)
        context.insert(checkIn)

        let book = Book(title: "Test Book", author: "Test Author", totalPages: 200, status: .reading)
        context.insert(book)

        let session = ReadingSession(book: book, date: Date(), pagesRead: 50)
        context.insert(session)

        let goal = Goal(type: .booksPerMonth, target: 4, period: .month)
        context.insert(goal)

        try context.save()

        let service = DataExportService(modelContext: context)
        let data = try service.exportAll()
        let decoded = try JSONDecoder.iso8601Decoder.decode(ExportData.self, from: data)

        #expect(decoded.dailyCheckIns.count == 1)
        #expect(decoded.books.count == 1)
        #expect(decoded.readingSessions.count == 1)
        #expect(decoded.goals.count == 1)
    }

    @Test("Export preserves book fields")
    func exportPreservesBookFields() throws {
        let context = try makeContext()

        let book = Book(
            title: "Dune",
            author: "Frank Herbert",
            isbn: "978-0441172719",
            totalPages: 412,
            currentPage: 200,
            percentComplete: 48.5,
            status: .reading,
            source: .manual
        )
        context.insert(book)
        try context.save()

        let service = DataExportService(modelContext: context)
        let data = try service.exportAll()
        let decoded = try JSONDecoder.iso8601Decoder.decode(ExportData.self, from: data)

        let exportedBook = try #require(decoded.books.first)
        #expect(exportedBook.title == "Dune")
        #expect(exportedBook.author == "Frank Herbert")
        #expect(exportedBook.isbn == "978-0441172719")
        #expect(exportedBook.totalPages == 412)
        #expect(exportedBook.currentPage == 200)
        #expect(exportedBook.status == "reading")
    }

    // MARK: - Import

    @Test("Import adds data to empty database")
    func importToEmpty() throws {
        let context = try makeContext()
        let service = DataExportService(modelContext: context)

        let importJson = """
        {
            "version": 1,
            "exportedAt": "2025-01-15T10:00:00Z",
            "dailyCheckIns": [
                {
                    "id": "11111111-1111-1111-1111-111111111111",
                    "date": "2025-01-15T00:00:00Z",
                    "didRead": true,
                    "source": "manual",
                    "createdAt": "2025-01-15T10:00:00Z"
                }
            ],
            "books": [
                {
                    "id": "22222222-2222-2222-2222-222222222222",
                    "title": "Imported Book",
                    "author": "Imported Author",
                    "coverUrl": null,
                    "isbn": null,
                    "googleBooksId": null,
                    "kindleAsin": null,
                    "totalPages": 300,
                    "currentPage": 150,
                    "percentComplete": 50.0,
                    "status": "reading",
                    "source": "manual",
                    "startedAt": "2025-01-10T00:00:00Z",
                    "completedAt": null,
                    "lastReadAt": "2025-01-15T00:00:00Z",
                    "createdAt": "2025-01-10T00:00:00Z",
                    "updatedAt": "2025-01-15T00:00:00Z"
                }
            ],
            "readingSessions": [],
            "goals": [
                {
                    "id": "33333333-3333-3333-3333-333333333333",
                    "type": "booksPerMonth",
                    "target": 4,
                    "period": "month",
                    "startDate": "2025-01-01T00:00:00Z",
                    "endDate": null,
                    "active": true,
                    "createdAt": "2025-01-01T00:00:00Z",
                    "updatedAt": "2025-01-01T00:00:00Z"
                }
            ]
        }
        """

        let data = importJson.data(using: .utf8)!
        let result = try service.importData(from: data)

        #expect(result.checkInsAdded == 1)
        #expect(result.booksAdded == 1)
        #expect(result.goalsAdded == 1)
        #expect(result.totalAdded == 2 + 1) // 1 checkIn + 1 book + 1 goal = 3
    }

    @Test("Import skips duplicate records by ID")
    func importSkipsDuplicates() throws {
        let context = try makeContext()

        // Pre-insert a book with a known ID
        let existingId = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let existing = Book(id: existingId, title: "Existing", author: "Author", status: .reading)
        context.insert(existing)
        try context.save()

        let service = DataExportService(modelContext: context)

        let importJson = """
        {
            "version": 1,
            "exportedAt": "2025-01-15T10:00:00Z",
            "dailyCheckIns": [],
            "books": [
                {
                    "id": "22222222-2222-2222-2222-222222222222",
                    "title": "Duplicate Book",
                    "author": "Another Author",
                    "coverUrl": null,
                    "isbn": null,
                    "googleBooksId": null,
                    "kindleAsin": null,
                    "totalPages": 100,
                    "currentPage": 50,
                    "percentComplete": 50.0,
                    "status": "reading",
                    "source": "manual",
                    "startedAt": null,
                    "completedAt": null,
                    "lastReadAt": null,
                    "createdAt": "2025-01-01T00:00:00Z",
                    "updatedAt": "2025-01-01T00:00:00Z"
                }
            ],
            "readingSessions": [],
            "goals": []
        }
        """

        let data = importJson.data(using: .utf8)!
        let result = try service.importData(from: data)

        #expect(result.booksSkipped == 1)
        #expect(result.booksAdded == 0)
    }

    // MARK: - Round-Trip

    @Test("Export then import produces identical data")
    func roundTrip() throws {
        // Source context with data
        let sourceContext = try makeContext()

        let checkIn = DailyCheckIn(date: Date(), didRead: true, source: .manual)
        sourceContext.insert(checkIn)

        let book = Book(title: "Round Trip", author: "Author", isbn: "1234567890", totalPages: 250, status: .reading)
        sourceContext.insert(book)

        let goal = Goal(type: .readingStreak, target: 30, period: .day)
        sourceContext.insert(goal)

        try sourceContext.save()

        // Export
        let exportService = DataExportService(modelContext: sourceContext)
        let exportedData = try exportService.exportAll()

        // Import into fresh context
        let targetContext = try makeContext()
        let importService = DataExportService(modelContext: targetContext)
        let result = try importService.importData(from: exportedData)

        #expect(result.checkInsAdded == 1)
        #expect(result.booksAdded == 1)
        #expect(result.goalsAdded == 1)

        // Verify the imported book
        let descriptor = FetchDescriptor<Book>()
        let importedBooks = try targetContext.fetch(descriptor)
        let importedBook = try #require(importedBooks.first)

        #expect(importedBook.title == "Round Trip")
        #expect(importedBook.author == "Author")
        #expect(importedBook.isbn == "1234567890")
        #expect(importedBook.totalPages == 250)
    }

    // MARK: - Import Result

    @Test("ImportResult summary describes added items")
    func importResultSummary() {
        var result = ImportResult()
        result.booksAdded = 3
        result.checkInsAdded = 5

        #expect(result.summary.contains("5 check-ins"))
        #expect(result.summary.contains("3 books"))
    }

    @Test("ImportResult summary for no new data")
    func importResultEmptySummary() {
        let result = ImportResult()
        #expect(result.summary.contains("No new data"))
    }
}

// MARK: - Helper

private extension JSONDecoder {
    static var iso8601Decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
