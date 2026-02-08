import Foundation

// MARK: - Book

enum BookStatus: String, Codable, CaseIterable, Identifiable {
    case reading
    case completed
    case paused
    case wantToRead

    var id: String { rawValue }

    var label: String {
        switch self {
        case .reading: "Reading"
        case .completed: "Completed"
        case .paused: "Paused"
        case .wantToRead: "Want to Read"
        }
    }

    var icon: String {
        switch self {
        case .reading: "book.fill"
        case .completed: "checkmark.circle.fill"
        case .paused: "pause.circle.fill"
        case .wantToRead: "bookmark.fill"
        }
    }
}

enum BookSource: String, Codable {
    case manual
    case kindle
}

// MARK: - Reading Session

enum SessionSource: String, Codable {
    case manual
    case kindle
}

// MARK: - Check-In

enum CheckInSource: String, Codable {
    case manual
    case catchUp
    case automatic
}

// MARK: - Goals

enum GoalType: String, Codable, CaseIterable, Identifiable {
    case dailyReading
    case booksPerMonth
    case booksPerYear
    case readingStreak
    case pagesPerDay

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dailyReading: "Daily Reading"
        case .booksPerMonth: "Books Per Month"
        case .booksPerYear: "Books Per Year"
        case .readingStreak: "Reading Streak"
        case .pagesPerDay: "Pages Per Day"
        }
    }

    var icon: String {
        switch self {
        case .dailyReading: "clock.fill"
        case .booksPerMonth: "calendar"
        case .booksPerYear: "star.fill"
        case .readingStreak: "flame.fill"
        case .pagesPerDay: "doc.text.fill"
        }
    }
}

enum GoalPeriod: String, Codable, CaseIterable {
    case day
    case week
    case month
    case year
}

// MARK: - Appearance

enum AppTheme: String, Codable, CaseIterable {
    case light
    case dark
    case auto

    var label: String {
        switch self {
        case .light: "Light"
        case .dark: "Dark"
        case .auto: "System"
        }
    }
}

// MARK: - Streak Milestones

enum StreakMilestone: Int, CaseIterable {
    case week = 7
    case twoWeeks = 14
    case month = 30
    case fiftyDays = 50
    case hundred = 100

    var message: String {
        switch self {
        case .week: "One whole week of reading!"
        case .twoWeeks: "Two weeks strong!"
        case .month: "A full month — you're a reader now!"
        case .fiftyDays: "50 days! That's incredible!"
        case .hundred: "100 days! You're unstoppable!"
        }
    }

    static func milestone(for count: Int) -> StreakMilestone? {
        StreakMilestone(rawValue: count)
    }
}
