import Foundation
import SwiftData

@Observable
final class CheckInService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Check In

    /// Record that the user read today
    func checkInToday() -> DailyCheckIn {
        let today = Date().startOfDay
        if let existing = fetchCheckIn(for: today) {
            existing.didRead = true
            existing.source = .manual
            return existing
        }
        let checkIn = DailyCheckIn(date: today, didRead: true, source: .manual)
        modelContext.insert(checkIn)
        return checkIn
    }

    /// Record a check-in for a specific date (used by catch-up flow)
    func checkIn(for date: Date, didRead: Bool) -> DailyCheckIn {
        let day = date.startOfDay
        if let existing = fetchCheckIn(for: day) {
            existing.didRead = didRead
            existing.source = .catchUp
            return existing
        }
        let checkIn = DailyCheckIn(date: day, didRead: didRead, source: .catchUp)
        modelContext.insert(checkIn)
        return checkIn
    }

    /// Mark that the celebration animation was shown for a check-in
    func markCelebrationShown(_ checkIn: DailyCheckIn) {
        checkIn.celebrationShown = true
    }

    // MARK: - Queries

    /// Get the check-in for today, if it exists
    func todayCheckIn() -> DailyCheckIn? {
        fetchCheckIn(for: Date().startOfDay)
    }

    /// Whether the user has checked in today
    var hasCheckedInToday: Bool {
        guard let checkIn = todayCheckIn() else { return false }
        return checkIn.didRead
    }

    /// Get check-in for a specific date
    func fetchCheckIn(for date: Date) -> DailyCheckIn? {
        let day = date.startOfDay
        let predicate = #Predicate<DailyCheckIn> { checkIn in
            checkIn.date == day
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        return try? modelContext.fetch(descriptor).first
    }

    /// Get all check-ins in a date range
    func fetchCheckIns(from start: Date, to end: Date) -> [DailyCheckIn] {
        let startDay = start.startOfDay
        let endDay = end.startOfDay
        let predicate = #Predicate<DailyCheckIn> { checkIn in
            checkIn.date >= startDay && checkIn.date <= endDay
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.date)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Missed Days

    /// Returns dates that have no check-in, between the last check-in and today.
    /// Capped at 7 days to avoid tedious catch-up sessions.
    func missedDays() -> [Date] {
        let today = Date().startOfDay
        let calendar = Calendar.current

        // Find the most recent check-in
        let descriptor = FetchDescriptor<DailyCheckIn>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let allCheckIns = (try? modelContext.fetch(descriptor)) ?? []

        guard let lastCheckIn = allCheckIns.first else {
            // No check-ins at all — don't show catch-up on first launch
            return []
        }

        let lastDate = lastCheckIn.date
        guard let dayAfterLast = calendar.date(byAdding: .day, value: 1, to: lastDate) else {
            return []
        }

        // Get all dates between last check-in and today (exclusive of both)
        let allMissedDates = dayAfterLast.datesUntil(today)

        // Filter out dates that already have check-ins
        let checkedInDates = Set(allCheckIns.map { $0.date })
        let uncheckedDates = allMissedDates.filter { !checkedInDates.contains($0) }

        // Cap at 7 days (most recent 7)
        return Array(uncheckedDates.suffix(7))
    }

    // MARK: - Save

    func save() {
        try? modelContext.save()
    }
}
