import Testing
import Foundation
import SwiftData
@testable import RaquelReadsCore

@Suite("CheckInService Tests")
struct CheckInServiceTests {

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: DailyCheckIn.self, StreakRecord.self, Book.self,
                 ReadingSession.self, Goal.self, UserSettings.self,
            configurations: config
        )
        return ModelContext(container)
    }

    // MARK: - Check-In Today

    @Test("Check in today creates a new check-in with didRead true")
    func checkInTodayCreatesRecord() throws {
        let context = try makeContext()
        let service = CheckInService(modelContext: context)

        let checkIn = service.checkInToday()

        #expect(checkIn.didRead == true)
        #expect(checkIn.source == .manual)
        #expect(checkIn.date == Date().startOfDay)
        #expect(checkIn.celebrationShown == false)
    }

    @Test("Checking in twice on the same day returns the same record")
    func checkInTodayIdempotent() throws {
        let context = try makeContext()
        let service = CheckInService(modelContext: context)

        let first = service.checkInToday()
        let second = service.checkInToday()

        #expect(first.id == second.id)
    }

    @Test("hasCheckedInToday is false before check-in, true after")
    func hasCheckedInTodayToggle() throws {
        let context = try makeContext()
        let service = CheckInService(modelContext: context)

        #expect(service.hasCheckedInToday == false)

        _ = service.checkInToday()
        service.save()

        #expect(service.hasCheckedInToday == true)
    }

    // MARK: - Catch-Up Check-In

    @Test("Check in for past date creates a catch-up record")
    func catchUpCheckIn() throws {
        let context = try makeContext()
        let service = CheckInService(modelContext: context)
        let calendar = Calendar.current
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: Date())!

        let checkIn = service.checkIn(for: threeDaysAgo, didRead: true)

        #expect(checkIn.didRead == true)
        #expect(checkIn.source == .catchUp)
        #expect(checkIn.date == threeDaysAgo.startOfDay)
    }

    @Test("Catch-up for existing date updates the record")
    func catchUpUpdatesExisting() throws {
        let context = try makeContext()
        let service = CheckInService(modelContext: context)
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!

        let first = service.checkIn(for: yesterday, didRead: false)
        let second = service.checkIn(for: yesterday, didRead: true)

        #expect(first.id == second.id)
        #expect(second.didRead == true)
    }

    // MARK: - Celebration Shown

    @Test("markCelebrationShown updates the flag")
    func markCelebrationShown() throws {
        let context = try makeContext()
        let service = CheckInService(modelContext: context)

        let checkIn = service.checkInToday()
        #expect(checkIn.celebrationShown == false)

        service.markCelebrationShown(checkIn)
        #expect(checkIn.celebrationShown == true)
    }

    // MARK: - Fetch Check-Ins

    @Test("fetchCheckIns returns check-ins in date range")
    func fetchByDateRange() throws {
        let context = try makeContext()
        let service = CheckInService(modelContext: context)
        let calendar = Calendar.current

        // Create check-ins for 5 days ago through 1 day ago
        for i in 1...5 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            _ = service.checkIn(for: date, didRead: i % 2 == 0)
        }
        service.save()

        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: Date())!
        let oneDayAgo = calendar.date(byAdding: .day, value: -1, to: Date())!
        let results = service.fetchCheckIns(from: threeDaysAgo, to: oneDayAgo)

        #expect(results.count == 3)
    }

    // MARK: - Missed Days

    @Test("missedDays returns empty on first launch")
    func missedDaysFirstLaunch() throws {
        let context = try makeContext()
        let service = CheckInService(modelContext: context)

        let missed = service.missedDays()
        #expect(missed.isEmpty)
    }

    @Test("missedDays returns unchecked days between last check-in and today")
    func missedDaysAfterGap() throws {
        let context = try makeContext()
        let service = CheckInService(modelContext: context)
        let calendar = Calendar.current

        // Check in 4 days ago
        let fourDaysAgo = calendar.date(byAdding: .day, value: -4, to: Date())!
        _ = service.checkIn(for: fourDaysAgo, didRead: true)
        service.save()

        let missed = service.missedDays()

        // Should have 3 missed days: -3, -2, -1
        #expect(missed.count == 3)
        // Should be sorted chronologically
        if missed.count >= 2 {
            #expect(missed[0] < missed[1])
        }
    }

    @Test("missedDays caps at 7 days")
    func missedDaysCappedAt7() throws {
        let context = try makeContext()
        let service = CheckInService(modelContext: context)
        let calendar = Calendar.current

        // Check in 15 days ago
        let fifteenDaysAgo = calendar.date(byAdding: .day, value: -15, to: Date())!
        _ = service.checkIn(for: fifteenDaysAgo, didRead: true)
        service.save()

        let missed = service.missedDays()

        #expect(missed.count == 7)
    }

    @Test("missedDays excludes days that already have check-ins")
    func missedDaysExcludesCheckedIn() throws {
        let context = try makeContext()
        let service = CheckInService(modelContext: context)
        let calendar = Calendar.current

        // Check in 5 days ago
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: Date())!
        _ = service.checkIn(for: fiveDaysAgo, didRead: true)

        // Also check in 3 days ago
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: Date())!
        _ = service.checkIn(for: threeDaysAgo, didRead: false)
        service.save()

        let missed = service.missedDays()

        // Should have 3 missed days: -4, -2, -1 (not -3, which has a check-in)
        #expect(missed.count == 3)
        let missedDates = Set(missed.map { $0.startOfDay })
        #expect(!missedDates.contains(threeDaysAgo.startOfDay))
    }
}
