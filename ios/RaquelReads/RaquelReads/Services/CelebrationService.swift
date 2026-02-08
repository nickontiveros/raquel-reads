import Foundation

@Observable
final class CelebrationService {
    var showConfetti = false
    var showMilestone = false
    var currentMilestone: StreakMilestone?
    var encouragingMessage: String = ""
    var isNewBest = false

    // MARK: - Encouraging Messages

    private static let dailyMessages = [
        "You showed up for yourself today.",
        "Reading is self-care. You earned this.",
        "Every page counts, even just one.",
        "Your future self is thanking you right now.",
        "Another day, another chapter in your story.",
        "You made time for what matters.",
        "That's the kind of day to be proud of.",
        "Keep going — you're building something great.",
    ]

    private static let streakMessages: [ClosedRange<Int>: [String]] = [
        2...4: [
            "You're building momentum!",
            "Look at you, showing up again!",
            "Two days in a row — that's how habits start.",
        ],
        5...7: [
            "Almost a full week — incredible!",
            "You're on a roll!",
            "This is becoming a real habit.",
        ],
        8...14: [
            "Over a week strong!",
            "You're proving it's not a fluke.",
            "Double digits incoming!",
        ],
        15...29: [
            "You're a reading machine!",
            "Most people would have stopped by now. Not you.",
            "This streak is getting serious.",
        ],
        30...99: [
            "A whole month of reading. Let that sink in.",
            "You've made reading part of who you are.",
            "This is genuinely impressive.",
        ],
        100...999: [
            "Triple digits. Legendary.",
            "You're in the reading hall of fame.",
            "100+ days. You're unstoppable.",
        ],
    ]

    // MARK: - Trigger Celebrations

    /// Trigger the full check-in celebration
    func celebrateCheckIn(streak: Int, milestone: StreakMilestone?, isNewBest: Bool) {
        self.isNewBest = isNewBest
        self.encouragingMessage = message(for: streak)
        self.currentMilestone = milestone

        // Always show confetti on check-in
        showConfetti = true

        // Show milestone overlay if applicable
        if milestone != nil {
            showMilestone = true
        }
    }

    /// Reset celebration state
    func reset() {
        showConfetti = false
        showMilestone = false
        currentMilestone = nil
        encouragingMessage = ""
        isNewBest = false
    }

    // MARK: - Message Selection

    private func message(for streak: Int) -> String {
        // If it's a new best, say so
        if isNewBest && streak > 1 {
            return "That's your longest streak ever! \(streak.pluralized("day"))!"
        }

        // Check streak-specific messages
        for (range, messages) in Self.streakMessages {
            if range.contains(streak) {
                return messages.randomElement() ?? Self.dailyMessages.randomElement()!
            }
        }

        // Default to daily messages
        return Self.dailyMessages.randomElement()!
    }
}
