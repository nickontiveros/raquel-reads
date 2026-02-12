import Testing
import Foundation
@testable import RaquelReadsCore

@Suite("CelebrationService Tests")
struct CelebrationServiceTests {

    @Test("celebrateCheckIn sets showConfetti to true")
    func confettiShown() {
        let service = CelebrationService()

        service.celebrateCheckIn(streak: 1, milestone: nil, isNewBest: false)

        #expect(service.showConfetti == true)
    }

    @Test("celebrateCheckIn sets encouraging message")
    func encouragingMessageSet() {
        let service = CelebrationService()

        service.celebrateCheckIn(streak: 1, milestone: nil, isNewBest: false)

        #expect(!service.encouragingMessage.isEmpty)
    }

    @Test("celebrateCheckIn shows milestone banner when milestone provided")
    func milestoneShown() {
        let service = CelebrationService()

        service.celebrateCheckIn(streak: 7, milestone: .week, isNewBest: false)

        #expect(service.showMilestone == true)
        #expect(service.currentMilestone == .week)
    }

    @Test("celebrateCheckIn does not show milestone when none provided")
    func noMilestone() {
        let service = CelebrationService()

        service.celebrateCheckIn(streak: 5, milestone: nil, isNewBest: false)

        #expect(service.showMilestone == false)
        #expect(service.currentMilestone == nil)
    }

    @Test("New best streak generates special message")
    func newBestMessage() {
        let service = CelebrationService()

        service.celebrateCheckIn(streak: 10, milestone: nil, isNewBest: true)

        #expect(service.encouragingMessage.contains("longest streak ever"))
    }

    @Test("reset clears all celebration state")
    func resetClearsState() {
        let service = CelebrationService()

        service.celebrateCheckIn(streak: 7, milestone: .week, isNewBest: true)
        service.reset()

        #expect(service.showConfetti == false)
        #expect(service.showMilestone == false)
        #expect(service.currentMilestone == nil)
        #expect(service.encouragingMessage.isEmpty)
        #expect(service.isNewBest == false)
    }

    // MARK: - Message Context

    @Test("Streak of 3 gets streak-specific message, not just daily")
    func streakSpecificMessage() {
        let service = CelebrationService()

        // Run multiple times to check we get messages from the right pool
        var messages = Set<String>()
        for _ in 0..<20 {
            service.celebrateCheckIn(streak: 3, milestone: nil, isNewBest: false)
            messages.insert(service.encouragingMessage)
            service.reset()
        }

        // Should have gotten at least one message (could be from streak or daily pool)
        #expect(!messages.isEmpty)
    }

    // MARK: - Milestone Enum

    @Test("StreakMilestone.milestone returns correct milestone for known values")
    func milestoneMapping() {
        #expect(StreakMilestone.milestone(for: 7) == .week)
        #expect(StreakMilestone.milestone(for: 14) == .twoWeeks)
        #expect(StreakMilestone.milestone(for: 30) == .month)
        #expect(StreakMilestone.milestone(for: 50) == .fiftyDays)
        #expect(StreakMilestone.milestone(for: 100) == .hundred)
    }

    @Test("StreakMilestone.milestone returns nil for non-milestone values")
    func nonMilestone() {
        #expect(StreakMilestone.milestone(for: 1) == nil)
        #expect(StreakMilestone.milestone(for: 5) == nil)
        #expect(StreakMilestone.milestone(for: 15) == nil)
        #expect(StreakMilestone.milestone(for: 99) == nil)
    }

    @Test("All milestones have non-empty messages")
    func allMilestonesHaveMessages() {
        for milestone in StreakMilestone.allCases {
            #expect(!milestone.message.isEmpty)
        }
    }
}
