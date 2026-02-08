import Foundation
import SwiftData

@Model
final class StreakRecord {
    @Attribute(.unique) var id: UUID
    var startDate: Date
    var endDate: Date?
    var length: Int
    var isCurrent: Bool
    var isBest: Bool

    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date? = nil,
        length: Int = 1,
        isCurrent: Bool = true,
        isBest: Bool = false
    ) {
        self.id = id
        self.startDate = Calendar.current.startOfDay(for: startDate)
        self.endDate = endDate.map { Calendar.current.startOfDay(for: $0) }
        self.length = length
        self.isCurrent = isCurrent
        self.isBest = isBest
    }
}
