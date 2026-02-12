import Testing
import Foundation
@testable import RaquelReadsCore

@Suite("Enum Tests")
struct EnumTests {

    // MARK: - BookStatus

    @Test("BookStatus has all 4 cases")
    func bookStatusCases() {
        #expect(BookStatus.allCases.count == 4)
    }

    @Test("BookStatus labels are non-empty")
    func bookStatusLabels() {
        for status in BookStatus.allCases {
            #expect(!status.label.isEmpty)
        }
    }

    @Test("BookStatus icons are valid SF Symbol names")
    func bookStatusIcons() {
        for status in BookStatus.allCases {
            #expect(!status.icon.isEmpty)
            #expect(status.icon.contains("."))  // SF Symbols contain dots
        }
    }

    @Test("BookStatus has correct labels")
    func bookStatusLabelValues() {
        #expect(BookStatus.reading.label == "Reading")
        #expect(BookStatus.completed.label == "Completed")
        #expect(BookStatus.paused.label == "Paused")
        #expect(BookStatus.wantToRead.label == "Want to Read")
    }

    @Test("BookStatus raw values are stable for Codable")
    func bookStatusRawValues() {
        #expect(BookStatus.reading.rawValue == "reading")
        #expect(BookStatus.completed.rawValue == "completed")
        #expect(BookStatus.paused.rawValue == "paused")
        #expect(BookStatus.wantToRead.rawValue == "wantToRead")
    }

    @Test("BookStatus Identifiable id is unique")
    func bookStatusIds() {
        let ids = BookStatus.allCases.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    // MARK: - BookSource

    @Test("BookSource has manual and kindle")
    func bookSourceCases() {
        #expect(BookSource.manual.rawValue == "manual")
        #expect(BookSource.kindle.rawValue == "kindle")
    }

    // MARK: - CheckInSource

    @Test("CheckInSource has all 3 cases")
    func checkInSourceCases() {
        #expect(CheckInSource.manual.rawValue == "manual")
        #expect(CheckInSource.catchUp.rawValue == "catchUp")
        #expect(CheckInSource.automatic.rawValue == "automatic")
    }

    // MARK: - GoalType

    @Test("GoalType has all 5 cases")
    func goalTypeCases() {
        #expect(GoalType.allCases.count == 5)
    }

    @Test("GoalType labels are non-empty")
    func goalTypeLabels() {
        for type in GoalType.allCases {
            #expect(!type.label.isEmpty)
        }
    }

    @Test("GoalType icons are non-empty")
    func goalTypeIcons() {
        for type in GoalType.allCases {
            #expect(!type.icon.isEmpty)
        }
    }

    @Test("GoalType Identifiable ids are unique")
    func goalTypeIds() {
        let ids = GoalType.allCases.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    // MARK: - GoalPeriod

    @Test("GoalPeriod has all 4 cases")
    func goalPeriodCases() {
        #expect(GoalPeriod.allCases.count == 4)
    }

    @Test("GoalPeriod raw values are stable")
    func goalPeriodRawValues() {
        #expect(GoalPeriod.day.rawValue == "day")
        #expect(GoalPeriod.week.rawValue == "week")
        #expect(GoalPeriod.month.rawValue == "month")
        #expect(GoalPeriod.year.rawValue == "year")
    }

    // MARK: - AppTheme

    @Test("AppTheme has all 3 cases")
    func appThemeCases() {
        #expect(AppTheme.allCases.count == 3)
    }

    @Test("AppTheme labels are correct")
    func appThemeLabels() {
        #expect(AppTheme.light.label == "Light")
        #expect(AppTheme.dark.label == "Dark")
        #expect(AppTheme.auto.label == "System")
    }

    // MARK: - StreakMilestone

    @Test("StreakMilestone has all 5 milestones")
    func streakMilestoneCases() {
        #expect(StreakMilestone.allCases.count == 5)
    }

    @Test("StreakMilestone raw values are correct day counts")
    func streakMilestoneValues() {
        #expect(StreakMilestone.week.rawValue == 7)
        #expect(StreakMilestone.twoWeeks.rawValue == 14)
        #expect(StreakMilestone.month.rawValue == 30)
        #expect(StreakMilestone.fiftyDays.rawValue == 50)
        #expect(StreakMilestone.hundred.rawValue == 100)
    }

    @Test("StreakMilestone messages are unique")
    func streakMilestoneUniqueMessages() {
        let messages = StreakMilestone.allCases.map(\.message)
        #expect(Set(messages).count == messages.count)
    }

    @Test("StreakMilestone.milestone(for:) returns correct milestone")
    func streakMilestoneForCount() {
        #expect(StreakMilestone.milestone(for: 7) == .week)
        #expect(StreakMilestone.milestone(for: 14) == .twoWeeks)
        #expect(StreakMilestone.milestone(for: 30) == .month)
        #expect(StreakMilestone.milestone(for: 50) == .fiftyDays)
        #expect(StreakMilestone.milestone(for: 100) == .hundred)
    }

    @Test("StreakMilestone.milestone(for:) returns nil for non-milestones")
    func streakMilestoneForNonMilestone() {
        #expect(StreakMilestone.milestone(for: 0) == nil)
        #expect(StreakMilestone.milestone(for: 1) == nil)
        #expect(StreakMilestone.milestone(for: 6) == nil)
        #expect(StreakMilestone.milestone(for: 8) == nil)
        #expect(StreakMilestone.milestone(for: 29) == nil)
        #expect(StreakMilestone.milestone(for: 51) == nil)
        #expect(StreakMilestone.milestone(for: 101) == nil)
    }

    // MARK: - Codable Round-Trip

    @Test("BookStatus survives JSON encode/decode")
    func bookStatusCodable() throws {
        let original = BookStatus.wantToRead
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BookStatus.self, from: data)
        #expect(decoded == original)
    }

    @Test("GoalType survives JSON encode/decode")
    func goalTypeCodable() throws {
        for type in GoalType.allCases {
            let data = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(GoalType.self, from: data)
            #expect(decoded == type)
        }
    }

    @Test("CheckInSource survives JSON encode/decode")
    func checkInSourceCodable() throws {
        for source in [CheckInSource.manual, .catchUp, .automatic] {
            let data = try JSONEncoder().encode(source)
            let decoded = try JSONDecoder().decode(CheckInSource.self, from: data)
            #expect(decoded == source)
        }
    }

    @Test("AppTheme survives JSON encode/decode")
    func appThemeCodable() throws {
        for theme in AppTheme.allCases {
            let data = try JSONEncoder().encode(theme)
            let decoded = try JSONDecoder().decode(AppTheme.self, from: data)
            #expect(decoded == theme)
        }
    }
}
