import UIKit

enum HapticManager {
    /// Satisfying success tap for daily check-in
    static func checkInSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Gentle bump for streak milestones
    static func streakMilestone() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred(intensity: 1.0)
    }

    /// Light tap for catch-up swipes
    static func swipe() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Soft tap for UI interactions
    static func tap() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
}
