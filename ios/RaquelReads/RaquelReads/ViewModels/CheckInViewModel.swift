import Foundation
import SwiftData
import Observation

@Observable
final class CheckInViewModel {
    let checkInService: CheckInService
    let streakService: StreakService
    let celebrationService: CelebrationService

    var hasCheckedInToday: Bool = false
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var readingDaysThisWeek: Int = 0
    var missedDays: [Date] = []
    var showCatchUp: Bool = false

    init(modelContext: ModelContext) {
        self.checkInService = CheckInService(modelContext: modelContext)
        self.streakService = StreakService(modelContext: modelContext)
        self.celebrationService = CelebrationService()
    }

    // MARK: - Load State

    func refresh() {
        hasCheckedInToday = checkInService.hasCheckedInToday
        currentStreak = streakService.currentStreak()
        bestStreak = streakService.bestStreak()
        readingDaysThisWeek = streakService.readingDaysThisWeek()

        let missed = checkInService.missedDays()
        missedDays = missed
        showCatchUp = !missed.isEmpty && !hasCheckedInToday
    }

    // MARK: - Check In

    func checkInToday() {
        let checkIn = checkInService.checkInToday()
        checkInService.save()

        // Refresh streak data
        let streak = streakService.currentStreak()
        let milestone = streakService.checkMilestone()
        let isNewBest = streakService.isNewBestStreak()

        // Trigger celebration
        HapticManager.checkInSuccess()
        celebrationService.celebrateCheckIn(
            streak: streak,
            milestone: milestone,
            isNewBest: isNewBest
        )

        // Mark celebration shown
        checkInService.markCelebrationShown(checkIn)
        checkInService.save()

        // Update local state
        refresh()
    }

    // MARK: - Catch-Up

    func catchUp(date: Date, didRead: Bool) {
        _ = checkInService.checkIn(for: date, didRead: didRead)
        checkInService.save()

        if didRead {
            HapticManager.swipe()
        }

        // Refresh after catch-up
        refresh()
    }

    func skipCatchUp() {
        // Mark all missed days as "no" and dismiss
        for date in missedDays {
            _ = checkInService.checkIn(for: date, didRead: false)
        }
        checkInService.save()
        showCatchUp = false
        refresh()
    }
}
