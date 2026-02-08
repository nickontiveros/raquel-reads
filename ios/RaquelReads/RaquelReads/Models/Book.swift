import Foundation
import SwiftData

@Model
final class Book {
    @Attribute(.unique) var id: UUID
    var title: String
    var author: String
    var coverUrl: String?
    var isbn: String?
    var googleBooksId: String?
    var kindleAsin: String?
    var totalPages: Int?
    var currentPage: Int
    var percentComplete: Double
    var status: BookStatus
    var source: BookSource
    var startedAt: Date?
    var completedAt: Date?
    var lastReadAt: Date?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ReadingSession.book)
    var sessions: [ReadingSession] = []

    init(
        id: UUID = UUID(),
        title: String,
        author: String,
        coverUrl: String? = nil,
        isbn: String? = nil,
        googleBooksId: String? = nil,
        kindleAsin: String? = nil,
        totalPages: Int? = nil,
        currentPage: Int = 0,
        percentComplete: Double = 0,
        status: BookStatus = .wantToRead,
        source: BookSource = .manual,
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        lastReadAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.coverUrl = coverUrl
        self.isbn = isbn
        self.googleBooksId = googleBooksId
        self.kindleAsin = kindleAsin
        self.totalPages = totalPages
        self.currentPage = currentPage
        self.percentComplete = percentComplete
        self.status = status
        self.source = source
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.lastReadAt = lastReadAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
