import Foundation
import SwiftData

@Model
final class ReadingSession {
    @Attribute(.unique) var id: UUID
    var book: Book?
    var checkIn: DailyCheckIn?
    var date: Date
    var pagesRead: Int
    var startPage: Int?
    var endPage: Int?
    var durationMinutes: Int?
    var notes: String?
    var source: SessionSource
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        book: Book? = nil,
        checkIn: DailyCheckIn? = nil,
        date: Date,
        pagesRead: Int = 0,
        startPage: Int? = nil,
        endPage: Int? = nil,
        durationMinutes: Int? = nil,
        notes: String? = nil,
        source: SessionSource = .manual,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.book = book
        self.checkIn = checkIn
        self.date = date
        self.pagesRead = pagesRead
        self.startPage = startPage
        self.endPage = endPage
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.source = source
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
