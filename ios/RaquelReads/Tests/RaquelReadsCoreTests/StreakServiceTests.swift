import Testing
import Foundation
import SwiftData
@testable import RaquelReadsCore

@Suite("StreakService Tests")
struct StreakServiceTests {

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: DailyCheckIn.self, StreakRecord.self, Book.self,
                 ReadingSession.self, Goal.self, UserSettings.self,
            configurations: config
        )
        return ModelContext(container)
    }

    private func addCheckIn(_ context: ModelContext, daysAgo: Int, didRead: Bool = true) {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
        let checkIn = DailyCheckIn(date: date, didRead: didRead, source: .manual)
        context.insert(checkIn)
        try? context.save()
    }

    // MARK: - Current Streak

    @Test("Current streak is 0 with no check-ins")
    func emptyStreak() throws {
        let context = try makeContext()
        let service = StreakService(modelContext: context)

        #expect(service.currentStreak() == 0)
    }

    @Test("Current streak counts consecutive days including today")
    func streakWithToday() throws {
        let context = try makeContext()
        let service = StreakService(modelContext: context)

        addCheckIn(context, daysAgo: 0) // today
        addCheckIn(context, daysAgo: 1) // yesterday
        addCheckIn(context, daysAgo: 2) // 2 days ago

        #expect(service.currentStreak() == 3)
    }

    @Test("Current streak counts from yesterday if today not checked in")
    func streakFromYesterday() throws {
        let context = try makeContext()
        let service = StreakService(modelContext: context)

        addCheckIn(context, daysAgo: 1) // yesterday
        addCheckIn(context, daysAgo: 2) // 2 days ago
        addCheckIn(context, daysAgo: 3) // 3 days ago

        #expect(service.currentStreak() == 3)
    }

    @Test("Current streak breaks on a gap")
    func streakBreaksOnGap() throws {
        let context = try makeContext()
        let service = StreakService(modelContext: context)

        addCheckIn(context, daysAgo: 0) // today
        addCheckIn(context, daysAgo: 1) // yesterday
        // gap at 2 days ago
        addCheckIn(context, daysAgo: 3) // 3 days ago

        #expect(service.currentStreak() == 2)
    }

    @Test("Current streak ignores didRead=false check-ins")
    func streakIgnoresNoReading() throws {
        let context = try makeContext()
        let service = StreakService(modelContext: context)

        addCheckIn(context, daysAgo: 0, didRead: true)
        addCheckIn(context, daysAgo: 1, didRead: false)  // checked in but didn't read
        addCheckIn(context, daysAgo: 2, didRead: true)

        // Streak should be 1 (only today), because yesterday was didRead=false
        #expect(service.currentStreak() == 1)
    }

    @Test("Current streak is 0 if no recent reading days")
    func noRecentReading() throws {
        let context = try makeContext()
        let service = StreakService(modelContext: context)

        addCheckIn(context, daysAgo: 5, didRead: true)

        // Neither today nor yesterday have a check-in
        #expect(service.currentStreak() == 0)
    }

    // MARK: - Best Streak

    @Test("Best streak finds the longest consecutive run")
    func bestStreakFindsLongest() throws {
        let context = try makeContext()
        let service = StreakService(modelContext: context)

        // Old streak: 4 days (10, 9, 8, 7 days ago)
        addCheckIn(context, daysAgo: 10)
        addCheckIn(context, daysAgo: 9)
        addCheckIn(context, daysAgo: 8)
        addCheckIn(context, daysAgo: 7)

        // Gap at 6, 5, 4, 3

        // Current streak: 2 days (1, 0 days ago)
        addCheckIn(context, daysAgo: 1)
        addCheckIn(context, daysAgo: 0)

        #expect(service.bestStreak() == 4)
    }

    @Test("Best streak is 1 with a single check-in")
    func bestStreakSingleDay() throws {
        let context = try makeContext()
        let service = StreakService(modelContext: context)

        addCheckIn(context, daysAgo: 0)

        #expect(service.bestStreak() == 1)
    }

    @Test("Best streak is 0 with no check-ins")
    func bestStreakEmpty() throws {
        let context = try makeContext()
        let service = StreakService(modelContext: context)

        #expect(service.bestStreak() == 0)
    }

    // MARK: - Total Reading Days

    @Test("Total reading days counts only didRead=true")
    func totalReadingDays() throws {
        let context = try makeContext()
        let service = StreakService(modelContext: context)

        addCheckIn(context, daysAgo: 0, didRead: true)
        addCheckIn(context, daysAgo: 1, didRead: false)
        addCheckIn(context, daysAgo: 2, didRead: true)
        addCheckIn(context, daysAgo: 5, didRead: true)

        #expect(service.totalReadingDays() == 3)
    }

    // MARK: - Reading Days This Week

    @Test("Reading days this week counts only current week")
    func readingDaysThisWeek() throws {
        let context = try makeContext()
        let service = StreakService(modelContext: context)

        // Check in today
        addCheckIn(context, daysAgo: 0, didRead: true)

        // The result should be at least 1 (today)
        let weekDays = service.readingDaysThisWeek()
        #expect(weekDays >= 1)
    }

    // MARK: - Milestones

    @Test("Milestone detected at exactly 7 days")
    func milestoneAt7() throws {
        let context = try makeContext()
        let service = StreakService(modelContext: context)

        for i in 0..<7 {
            addCheckIn(context, daysAgo: i)
        }

        let milestone = service.checkMilestone()
        #expect(milestone == .week)
    }

    @Test("No milestone at non-milestone streak counts")
    func noMilestoneAt5() throws {
        let context = try makeContext()
        let service = StreakService(modelContext: context)

        for i in 0..<5 {
            addCheckIn(context, daysAgo: i)
        }

        let milestone = service.checkMilestone()
        #expect(milestone == nil)
    }

    @Test("isNewBestStreak detects personal best")
    func newBestStreak() throws {
        let context = try makeContext()
        let service = StreakService(modelContext: context)

        // Only streak ever: 3 days
        addCheckIn(context, daysAgo: 0)
        addCheckIn(context, daysAgo: 1)
        addCheckIn(context, daysAgo: 2)

        #expect(service.isNewBestStreak() == true)
    }

    @Test("isNewBestStreak is false when current < best")
    func notNewBestStreak() throws {
        let context = try makeContext()
        let service = StreakService(modelContext: context)

        // Old streak: 5 days (10..6 days ago)
        for i in 6...10 {
            addCheckIn(context, daysAgo: i)
        }

        // Current streak: 2 days (today + yesterday)
        addCheckIn(context, daysAgo: 0)
        addCheckIn(context, daysAgo: 1)

        #expect(service.isNewBestStreak() == false)
    }
}
