import Foundation
import SwiftData

@Observable
final class StreakService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Streak Calculation

    /// Calculate the current streak from check-in data.
    /// A streak is consecutive days where didRead == true, counting back from today (or yesterday if today hasn't been checked in yet).
    func currentStreak() -> Int {
        let calendar = Calendar.current
        let today = Date().startOfDay

        // Fetch all positive check-ins, sorted by date descending
        let predicate = #Predicate<DailyCheckIn> { $0.didRead == true }
        let descriptor = FetchDescriptor<DailyCheckIn>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        guard let checkIns = try? modelContext.fetch(descriptor), !checkIns.isEmpty else {
            return 0
        }

        let dates = Set(checkIns.map { $0.date })

        // Start counting from today or yesterday
        var current = today
        if !dates.contains(today) {
            // If today isn't checked in, start from yesterday
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
                return 0
            }
            current = yesterday
        }

        var streak = 0
        while dates.contains(current) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: current) else { break }
            current = prev
        }

        return streak
    }

    /// The longest streak ever achieved
    func bestStreak() -> Int {
        let predicate = #Predicate<DailyCheckIn> { $0.didRead == true }
        let descriptor = FetchDescriptor<DailyCheckIn>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date)]
        )
        guard let checkIns = try? modelContext.fetch(descriptor), !checkIns.isEmpty else {
            return 0
        }

        let calendar = Calendar.current
        var best = 1
        var current = 1

        for i in 1..<checkIns.count {
            let prevDate = checkIns[i - 1].date
            let thisDate = checkIns[i].date
            let daysBetween = calendar.dateComponents([.day], from: prevDate, to: thisDate).day ?? 0

            if daysBetween == 1 {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }

        return best
    }

    /// Total number of days the user has read
    func totalReadingDays() -> Int {
        let predicate = #Predicate<DailyCheckIn> { $0.didRead == true }
        let descriptor = FetchDescriptor<DailyCheckIn>(predicate: predicate)
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    /// Reading days this week (Mon-Sun)
    func readingDaysThisWeek() -> Int {
        let calendar = Calendar.current
        let today = Date().startOfDay
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return 0
        }
        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return 0
        }

        let predicate = #Predicate<DailyCheckIn> { checkIn in
            checkIn.didRead == true && checkIn.date >= weekStart && checkIn.date < weekEnd
        }
        let descriptor = FetchDescriptor<DailyCheckIn>(predicate: predicate)
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    // MARK: - Milestone Detection

    /// Check if the current streak hits a milestone, returns the milestone if so
    func checkMilestone() -> StreakMilestone? {
        let streak = currentStreak()
        return StreakMilestone.milestone(for: streak)
    }

    /// Returns whether this is a new personal best streak
    func isNewBestStreak() -> Bool {
        let current = currentStreak()
        let best = bestStreak()
        return current > 0 && current >= best
    }
}
