import Foundation
import SwiftData

@Observable
final class GoalService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    func addGoal(
        type: GoalType,
        target: Int,
        period: GoalPeriod,
        startDate: Date = Date()
    ) -> Goal {
        let goal = Goal(
            type: type,
            target: target,
            period: period,
            startDate: startDate
        )
        modelContext.insert(goal)
        save()
        return goal
    }

    // MARK: - Read

    func fetchActive() -> [Goal] {
        let predicate = #Predicate<Goal> { $0.active == true }
        let descriptor = FetchDescriptor<Goal>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchAll() -> [Goal] {
        let descriptor = FetchDescriptor<Goal>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Progress Calculation

    /// Calculate progress for a goal based on current data.
    /// Returns a value between 0.0 and 1.0 (percentage complete).
    func calculateProgress(for goal: Goal, using context: GoalProgressContext) -> GoalProgress {
        let current: Int
        let target = goal.target

        switch goal.type {
        case .dailyReading:
            // Minutes read today
            current = context.minutesReadToday
        case .booksPerMonth:
            current = context.booksCompletedThisMonth
        case .booksPerYear:
            current = context.booksCompletedThisYear
        case .readingStreak:
            current = context.currentStreak
        case .pagesPerDay:
            current = context.pagesReadToday
        }

        let percentage = target > 0 ? min(1.0, Double(current) / Double(target)) : 0
        let isComplete = current >= target

        return GoalProgress(
            goal: goal,
            current: current,
            target: target,
            percentage: percentage,
            isComplete: isComplete
        )
    }

    /// Calculate progress for all active goals
    func calculateAllProgress(using context: GoalProgressContext) -> [GoalProgress] {
        fetchActive().map { calculateProgress(for: $0, using: context) }
    }

    // MARK: - Update

    func deactivate(_ goal: Goal) {
        goal.active = false
        goal.endDate = Date()
        goal.updatedAt = Date()
        save()
    }

    func updateTarget(_ goal: Goal, target: Int) {
        goal.target = target
        goal.updatedAt = Date()
        save()
    }

    // MARK: - Delete

    func delete(_ goal: Goal) {
        modelContext.delete(goal)
        save()
    }

    // MARK: - Save

    func save() {
        try? modelContext.save()
    }
}

// MARK: - Progress Types

/// Context data needed to calculate goal progress.
/// Gathered from other services and passed in to avoid circular dependencies.
struct GoalProgressContext {
    let minutesReadToday: Int
    let pagesReadToday: Int
    let currentStreak: Int
    let booksCompletedThisMonth: Int
    let booksCompletedThisYear: Int

    static let empty = GoalProgressContext(
        minutesReadToday: 0,
        pagesReadToday: 0,
        currentStreak: 0,
        booksCompletedThisMonth: 0,
        booksCompletedThisYear: 0
    )
}

struct GoalProgress: Identifiable {
    let goal: Goal
    let current: Int
    let target: Int
    let percentage: Double
    let isComplete: Bool

    var id: UUID { goal.id }

    var displayString: String {
        "\(current) / \(target)"
    }
}
