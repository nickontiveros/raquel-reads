import Testing
import Foundation
import SwiftData
@testable import RaquelReadsCore

@Suite("Integration Tests")
struct IntegrationTests {

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

    // MARK: - Full Check-In → Streak → Celebration Flow

    @Test("First ever check-in creates streak of 1 with celebration")
    func firstCheckIn() throws {
        let context = try makeContext()
        let checkInService = CheckInService(modelContext: context)
        let streakService = StreakService(modelContext: context)
        let celebrationService = CelebrationService()

        // Initial state
        #expect(checkInService.hasCheckedInToday == false)
        #expect(streakService.currentStreak() == 0)
        #expect(checkInService.missedDays().isEmpty)

        // Check in
        let checkIn = checkInService.checkInToday()
        checkInService.save()

        // Verify check-in
        #expect(checkIn.didRead == true)
        #expect(checkInService.hasCheckedInToday == true)

        // Verify streak
        let streak = streakService.currentStreak()
        #expect(streak == 1)

        // Trigger celebration
        let milestone = streakService.checkMilestone()
        let isNewBest = streakService.isNewBestStreak()
        celebrationService.celebrateCheckIn(streak: streak, milestone: milestone, isNewBest: isNewBest)

        #expect(celebrationService.showConfetti == true)
        #expect(!celebrationService.encouragingMessage.isEmpty)
        #expect(isNewBest == true) // First streak is always a new best
        #expect(milestone == nil) // 1 day is not a milestone
    }

    @Test("7-day streak triggers week milestone")
    func weekMilestone() throws {
        let context = try makeContext()
        let streakService = StreakService(modelContext: context)
        let celebrationService = CelebrationService()

        // Build a 6-day streak (days 6 through 1 ago)
        for i in 1...6 {
            addCheckIn(context, daysAgo: i)
        }

        // Check in today to make 7
        addCheckIn(context, daysAgo: 0)

        let streak = streakService.currentStreak()
        #expect(streak == 7)

        let milestone = streakService.checkMilestone()
        #expect(milestone == .week)

        celebrationService.celebrateCheckIn(streak: streak, milestone: milestone, isNewBest: true)
        #expect(celebrationService.showMilestone == true)
        #expect(celebrationService.currentMilestone == .week)
    }

    // MARK: - Catch-Up Flow

    @Test("Full catch-up flow restores streak")
    func catchUpRestoresStreak() throws {
        let context = try makeContext()
        let checkInService = CheckInService(modelContext: context)
        let streakService = StreakService(modelContext: context)

        // Check in 5 days ago
        addCheckIn(context, daysAgo: 5)

        // Missed days 4, 3, 2, 1
        let missed = checkInService.missedDays()
        #expect(missed.count == 4)

        // Streak should be 0 (too long since last check-in)
        #expect(streakService.currentStreak() == 0)

        // Catch up: mark all missed days as "yes"
        for date in missed {
            _ = checkInService.checkIn(for: date, didRead: true)
        }
        checkInService.save()

        // Check in today
        _ = checkInService.checkInToday()
        checkInService.save()

        // Streak should now be 6 (5 days ago + 4 catch-up + today)
        #expect(streakService.currentStreak() == 6)
    }

    @Test("Partial catch-up breaks streak correctly")
    func partialCatchUp() throws {
        let context = try makeContext()
        let checkInService = CheckInService(modelContext: context)
        let streakService = StreakService(modelContext: context)

        // Check in 4 days ago
        addCheckIn(context, daysAgo: 4)

        let missed = checkInService.missedDays()
        let calendar = Calendar.current

        // Mark day -3 as yes, day -2 as no, day -1 as yes
        for date in missed {
            let daysAgo = calendar.startOfDay(for: Date()).days(to: calendar.startOfDay(for: date))
            // daysAgo is negative here since date is in the past
            let didRead = (daysAgo != -2) // Skip day -2
            _ = checkInService.checkIn(for: date, didRead: didRead)
        }
        checkInService.save()

        // Check in today
        _ = checkInService.checkInToday()
        checkInService.save()

        // Streak should be 2 (yesterday + today), broken by the "no" at day -2
        #expect(streakService.currentStreak() == 2)
    }

    // MARK: - Book + Session Integration

    @Test("Logging sessions through a book's lifecycle")
    func bookLifecycle() throws {
        let context = try makeContext()
        let bookService = BookService(modelContext: context)
        let sessionService = ReadingSessionService(modelContext: context)

        // Add a book
        let book = bookService.addBook(
            title: "The Hobbit",
            author: "J.R.R. Tolkien",
            totalPages: 310,
            status: .reading
        )
        #expect(book.status == .reading)
        #expect(book.startedAt != nil)

        // Log some reading
        _ = sessionService.logSession(book: book, pagesRead: 50, startPage: 0, endPage: 50)
        #expect(book.currentPage == 50)
        #expect(book.percentComplete > 0)

        // Log more
        _ = sessionService.logSession(book: book, pagesRead: 100, startPage: 50, endPage: 150)
        #expect(book.currentPage == 150)

        // Verify sessions are linked
        let bookSessions = sessionService.fetchByBook(book)
        #expect(bookSessions.count == 2)

        // Read to the end — should auto-complete
        _ = sessionService.logSession(book: book, pagesRead: 160, startPage: 150, endPage: 310)
        bookService.updateProgress(book, currentPage: 310)
        #expect(book.status == .completed)
        #expect(book.completedAt != nil)
    }

    // MARK: - Goal Progress Integration

    @Test("Goal progress reflects actual data")
    func goalProgressReflectsData() throws {
        let context = try makeContext()
        let goalService = GoalService(modelContext: context)
        let bookService = BookService(modelContext: context)
        let streakService = StreakService(modelContext: context)

        // Create goals
        let streakGoal = goalService.addGoal(type: .readingStreak, target: 7, period: .day)
        let booksGoal = goalService.addGoal(type: .booksPerMonth, target: 4, period: .month)

        // Build a 3-day streak
        for i in 0...2 {
            addCheckIn(context, daysAgo: i)
        }

        // Complete 2 books
        let book1 = bookService.addBook(title: "Book 1", author: "A", status: .completed)
        book1.completedAt = Date()
        let book2 = bookService.addBook(title: "Book 2", author: "B", status: .completed)
        book2.completedAt = Date()
        bookService.save()

        // Calculate progress
        let progressContext = GoalProgressContext(
            minutesReadToday: 0,
            pagesReadToday: 0,
            currentStreak: streakService.currentStreak(),
            booksCompletedThisMonth: 2,
            booksCompletedThisYear: 2
        )

        let streakProgress = goalService.calculateProgress(for: streakGoal, using: progressContext)
        #expect(streakProgress.current == 3)
        #expect(streakProgress.target == 7)
        #expect(streakProgress.isComplete == false)

        let booksProgress = goalService.calculateProgress(for: booksGoal, using: progressContext)
        #expect(booksProgress.current == 2)
        #expect(booksProgress.target == 4)
        #expect(booksProgress.percentage == 0.5)
    }

    // MARK: - Export/Import Integration

    @Test("Full data round-trip preserves everything")
    func fullRoundTrip() throws {
        let sourceContext = try makeContext()

        // Create rich data
        let checkIn = DailyCheckIn(date: Date(), didRead: true)
        sourceContext.insert(checkIn)

        let book = Book(
            title: "Round Trip Book",
            author: "Author Name",
            isbn: "9780441172719",
            totalPages: 412,
            currentPage: 200,
            percentComplete: 48.5,
            status: .reading,
            source: .manual
        )
        sourceContext.insert(book)

        let session = ReadingSession(
            book: book,
            date: Date(),
            pagesRead: 50,
            startPage: 150,
            endPage: 200,
            durationMinutes: 30,
            notes: "Great chapter!"
        )
        sourceContext.insert(session)

        let goal = Goal(type: .booksPerYear, target: 24, period: .year)
        sourceContext.insert(goal)

        try sourceContext.save()

        // Export
        let exportService = DataExportService(modelContext: sourceContext)
        let exportedData = try exportService.exportAll()

        // Import to fresh context
        let targetContext = try makeContext()
        let importService = DataExportService(modelContext: targetContext)
        let result = try importService.importData(from: exportedData)

        #expect(result.checkInsAdded == 1)
        #expect(result.booksAdded == 1)
        #expect(result.sessionsAdded == 1)
        #expect(result.goalsAdded == 1)
        #expect(result.totalSkipped == 0)

        // Verify imported data integrity
        let importedBooks = try targetContext.fetch(FetchDescriptor<Book>())
        let importedBook = try #require(importedBooks.first)
        #expect(importedBook.title == "Round Trip Book")
        #expect(importedBook.isbn == "9780441172719")
        #expect(importedBook.currentPage == 200)

        let importedGoals = try targetContext.fetch(FetchDescriptor<Goal>())
        let importedGoal = try #require(importedGoals.first)
        #expect(importedGoal.type == .booksPerYear)
        #expect(importedGoal.target == 24)

        // Second import should skip everything
        let result2 = try importService.importData(from: exportedData)
        #expect(result2.totalAdded == 0)
        #expect(result2.totalSkipped == 4)
    }

    // MARK: - Edge Cases

    @Test("Checking in after streak freeze doesn't count frozen days")
    func streakWithFrozenDays() throws {
        let context = try makeContext()
        let checkInService = CheckInService(modelContext: context)
        let streakService = StreakService(modelContext: context)

        // Check in 3 days ago
        addCheckIn(context, daysAgo: 3)
        // Skip days -2 and -1 (simulating a freeze)
        // Check in today
        _ = checkInService.checkInToday()
        checkInService.save()

        // Without freeze logic in streak calculation, streak is 1
        // (freeze would need to be accounted for in StreakService)
        #expect(streakService.currentStreak() == 1)
    }

    @Test("Multiple check-ins on the same day are idempotent")
    func multipleCheckInsSameDay() throws {
        let context = try makeContext()
        let checkInService = CheckInService(modelContext: context)
        let streakService = StreakService(modelContext: context)

        // Check in 3 times today
        let first = checkInService.checkInToday()
        let second = checkInService.checkInToday()
        let third = checkInService.checkInToday()
        checkInService.save()

        // All should be the same record
        #expect(first.id == second.id)
        #expect(second.id == third.id)

        // Streak should still be 1
        #expect(streakService.currentStreak() == 1)
    }

    @Test("Empty database has safe defaults everywhere")
    func emptyDatabaseDefaults() throws {
        let context = try makeContext()
        let checkInService = CheckInService(modelContext: context)
        let streakService = StreakService(modelContext: context)
        let bookService = BookService(modelContext: context)
        let sessionService = ReadingSessionService(modelContext: context)
        let goalService = GoalService(modelContext: context)

        #expect(checkInService.hasCheckedInToday == false)
        #expect(checkInService.todayCheckIn() == nil)
        #expect(checkInService.missedDays().isEmpty)
        #expect(streakService.currentStreak() == 0)
        #expect(streakService.bestStreak() == 0)
        #expect(streakService.totalReadingDays() == 0)
        #expect(streakService.checkMilestone() == nil)
        #expect(streakService.isNewBestStreak() == false)
        #expect(bookService.fetchAll().isEmpty)
        #expect(bookService.completedCount() == 0)
        #expect(bookService.totalPagesRead() == 0)
        #expect(sessionService.fetchAll().isEmpty)
        #expect(sessionService.totalPagesRead() == 0)
        #expect(sessionService.totalMinutesRead() == 0)
        #expect(goalService.fetchActive().isEmpty)
        #expect(goalService.calculateAllProgress(using: .empty).isEmpty)
    }
}
