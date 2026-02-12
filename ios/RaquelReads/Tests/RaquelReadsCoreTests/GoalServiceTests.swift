import Testing
import Foundation
import SwiftData
@testable import RaquelReadsCore

@Suite("GoalService Tests")
struct GoalServiceTests {

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: DailyCheckIn.self, StreakRecord.self, Book.self,
                 ReadingSession.self, Goal.self, UserSettings.self,
            configurations: config
        )
        return ModelContext(container)
    }

    // MARK: - Create

    @Test("addGoal creates an active goal")
    func addGoal() throws {
        let context = try makeContext()
        let service = GoalService(modelContext: context)

        let goal = service.addGoal(type: .booksPerMonth, target: 4, period: .month)

        #expect(goal.type == .booksPerMonth)
        #expect(goal.target == 4)
        #expect(goal.period == .month)
        #expect(goal.active == true)
        #expect(goal.endDate == nil)
    }

    // MARK: - Fetch

    @Test("fetchActive returns only active goals")
    func fetchActive() throws {
        let context = try makeContext()
        let service = GoalService(modelContext: context)

        let goal1 = service.addGoal(type: .booksPerMonth, target: 4, period: .month)
        _ = service.addGoal(type: .readingStreak, target: 30, period: .day)

        service.deactivate(goal1)

        let active = service.fetchActive()
        #expect(active.count == 1)
        #expect(active.first?.type == .readingStreak)
    }

    @Test("fetchAll returns all goals including inactive")
    func fetchAll() throws {
        let context = try makeContext()
        let service = GoalService(modelContext: context)

        let goal1 = service.addGoal(type: .booksPerMonth, target: 4, period: .month)
        _ = service.addGoal(type: .readingStreak, target: 30, period: .day)

        service.deactivate(goal1)

        let all = service.fetchAll()
        #expect(all.count == 2)
    }

    // MARK: - Progress Calculation

    @Test("Progress for booksPerMonth calculates correctly")
    func booksPerMonthProgress() throws {
        let context = try makeContext()
        let service = GoalService(modelContext: context)

        let goal = service.addGoal(type: .booksPerMonth, target: 4, period: .month)
        let progressContext = GoalProgressContext(
            minutesReadToday: 0,
            pagesReadToday: 0,
            currentStreak: 0,
            booksCompletedThisMonth: 2,
            booksCompletedThisYear: 10
        )

        let progress = service.calculateProgress(for: goal, using: progressContext)

        #expect(progress.current == 2)
        #expect(progress.target == 4)
        #expect(progress.percentage == 0.5)
        #expect(progress.isComplete == false)
    }

    @Test("Progress for readingStreak uses current streak")
    func readingStreakProgress() throws {
        let context = try makeContext()
        let service = GoalService(modelContext: context)

        let goal = service.addGoal(type: .readingStreak, target: 30, period: .day)
        let progressContext = GoalProgressContext(
            minutesReadToday: 0,
            pagesReadToday: 0,
            currentStreak: 15,
            booksCompletedThisMonth: 0,
            booksCompletedThisYear: 0
        )

        let progress = service.calculateProgress(for: goal, using: progressContext)

        #expect(progress.current == 15)
        #expect(progress.target == 30)
        #expect(progress.percentage == 0.5)
    }

    @Test("Progress for pagesPerDay uses today's pages")
    func pagesPerDayProgress() throws {
        let context = try makeContext()
        let service = GoalService(modelContext: context)

        let goal = service.addGoal(type: .pagesPerDay, target: 50, period: .day)
        let progressContext = GoalProgressContext(
            minutesReadToday: 30,
            pagesReadToday: 50,
            currentStreak: 5,
            booksCompletedThisMonth: 1,
            booksCompletedThisYear: 3
        )

        let progress = service.calculateProgress(for: goal, using: progressContext)

        #expect(progress.current == 50)
        #expect(progress.target == 50)
        #expect(progress.percentage == 1.0)
        #expect(progress.isComplete == true)
    }

    @Test("Progress percentage caps at 1.0")
    func progressCapsAt100Percent() throws {
        let context = try makeContext()
        let service = GoalService(modelContext: context)

        let goal = service.addGoal(type: .booksPerYear, target: 12, period: .year)
        let progressContext = GoalProgressContext(
            minutesReadToday: 0,
            pagesReadToday: 0,
            currentStreak: 0,
            booksCompletedThisMonth: 5,
            booksCompletedThisYear: 20  // Over target
        )

        let progress = service.calculateProgress(for: goal, using: progressContext)

        #expect(progress.percentage == 1.0)
        #expect(progress.isComplete == true)
    }

    @Test("calculateAllProgress returns progress for all active goals")
    func calculateAllProgress() throws {
        let context = try makeContext()
        let service = GoalService(modelContext: context)

        _ = service.addGoal(type: .booksPerMonth, target: 4, period: .month)
        _ = service.addGoal(type: .readingStreak, target: 30, period: .day)

        let allProgress = service.calculateAllProgress(using: .empty)
        #expect(allProgress.count == 2)
    }

    // MARK: - Update

    @Test("deactivate sets active to false and endDate")
    func deactivateGoal() throws {
        let context = try makeContext()
        let service = GoalService(modelContext: context)

        let goal = service.addGoal(type: .booksPerMonth, target: 4, period: .month)
        service.deactivate(goal)

        #expect(goal.active == false)
        #expect(goal.endDate != nil)
    }

    @Test("updateTarget changes the goal target")
    func updateTarget() throws {
        let context = try makeContext()
        let service = GoalService(modelContext: context)

        let goal = service.addGoal(type: .pagesPerDay, target: 20, period: .day)
        service.updateTarget(goal, target: 50)

        #expect(goal.target == 50)
    }

    // MARK: - Delete

    @Test("delete removes the goal")
    func deleteGoal() throws {
        let context = try makeContext()
        let service = GoalService(modelContext: context)

        let goal = service.addGoal(type: .booksPerMonth, target: 4, period: .month)
        #expect(service.fetchAll().count == 1)

        service.delete(goal)
        #expect(service.fetchAll().count == 0)
    }

    // MARK: - Display

    @Test("GoalProgress displayString formats correctly")
    func displayString() throws {
        let context = try makeContext()
        let service = GoalService(modelContext: context)

        let goal = service.addGoal(type: .booksPerMonth, target: 4, period: .month)
        let progressContext = GoalProgressContext(
            minutesReadToday: 0,
            pagesReadToday: 0,
            currentStreak: 0,
            booksCompletedThisMonth: 2,
            booksCompletedThisYear: 0
        )

        let progress = service.calculateProgress(for: goal, using: progressContext)
        #expect(progress.displayString == "2 / 4")
    }
}
