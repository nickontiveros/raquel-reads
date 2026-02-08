import Foundation
import SwiftData

@Model
final class Goal {
    @Attribute(.unique) var id: UUID
    var type: GoalType
    var target: Int
    var period: GoalPeriod
    var startDate: Date
    var endDate: Date?
    var active: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        type: GoalType,
        target: Int,
        period: GoalPeriod,
        startDate: Date = Date(),
        endDate: Date? = nil,
        active: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.target = target
        self.period = period
        self.startDate = startDate
        self.endDate = endDate
        self.active = active
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
