import Foundation
import SwiftData

@Model
final class DailyCheckIn {
    @Attribute(.unique) var id: UUID
    var date: Date
    var didRead: Bool
    var source: CheckInSource
    var celebrationShown: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        date: Date,
        didRead: Bool,
        source: CheckInSource = .manual,
        celebrationShown: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.didRead = didRead
        self.source = source
        self.celebrationShown = celebrationShown
        self.createdAt = createdAt
    }
}
