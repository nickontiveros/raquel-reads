import Testing
import Foundation
@testable import RaquelReadsCore

@Suite("Extension Tests")
struct ExtensionTests {

    // MARK: - Date.startOfDay

    @Test("startOfDay strips time components")
    func startOfDay() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2025
        components.month = 6
        components.day = 15
        components.hour = 14
        components.minute = 30
        components.second = 45

        let date = calendar.date(from: components)!
        let startOfDay = date.startOfDay

        let resultComponents = calendar.dateComponents([.hour, .minute, .second], from: startOfDay)
        #expect(resultComponents.hour == 0)
        #expect(resultComponents.minute == 0)
        #expect(resultComponents.second == 0)
    }

    // MARK: - Date.isToday

    @Test("isToday returns true for current date")
    func isTodayTrue() {
        #expect(Date().isToday == true)
    }

    @Test("isToday returns false for yesterday")
    func isTodayFalse() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        #expect(yesterday.isToday == false)
    }

    // MARK: - Date.isYesterday

    @Test("isYesterday returns true for yesterday")
    func isYesterdayTrue() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        #expect(yesterday.isYesterday == true)
    }

    @Test("isYesterday returns false for today")
    func isYesterdayFalse() {
        #expect(Date().isYesterday == false)
    }

    // MARK: - Date.days(to:)

    @Test("days(to:) calculates days between dates correctly")
    func daysBetween() {
        let calendar = Calendar.current
        let today = Date()
        let fiveDaysLater = calendar.date(byAdding: .day, value: 5, to: today)!

        #expect(today.days(to: fiveDaysLater) == 5)
    }

    @Test("days(to:) returns negative for past dates")
    func daysBetweenNegative() {
        let calendar = Calendar.current
        let today = Date()
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!

        #expect(today.days(to: threeDaysAgo) == -3)
    }

    @Test("days(to:) returns 0 for same day")
    func daysBetweenSameDay() {
        let date = Date()
        #expect(date.days(to: date) == 0)
    }

    // MARK: - Date.datesUntil

    @Test("datesUntil returns correct dates")
    func datesUntil() {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 3, to: start)!

        let dates = start.datesUntil(end)

        #expect(dates.count == 3)
        #expect(dates[0] == start)
        #expect(dates[1] == calendar.date(byAdding: .day, value: 1, to: start))
        #expect(dates[2] == calendar.date(byAdding: .day, value: 2, to: start))
    }

    @Test("datesUntil returns empty for same date")
    func datesUntilSameDate() {
        let date = Date().startOfDay
        let dates = date.datesUntil(date)
        #expect(dates.isEmpty)
    }

    @Test("datesUntil returns empty when end is before start")
    func datesUntilReversed() {
        let calendar = Calendar.current
        let today = Date().startOfDay
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let dates = today.datesUntil(yesterday)
        #expect(dates.isEmpty)
    }

    // MARK: - Date.friendlyDayString

    @Test("friendlyDayString produces readable format")
    func friendlyDayString() {
        var components = DateComponents()
        components.year = 2025
        components.month = 2
        components.day = 4

        let date = Calendar.current.date(from: components)!
        let result = date.friendlyDayString

        // Should contain "Feb" and "4"
        #expect(result.contains("Feb"))
        #expect(result.contains("4"))
    }

    // MARK: - Date.shortDayString

    @Test("shortDayString produces compact format")
    func shortDayString() {
        var components = DateComponents()
        components.year = 2025
        components.month = 12
        components.day = 25

        let date = Calendar.current.date(from: components)!
        let result = date.shortDayString

        #expect(result.contains("Dec"))
        #expect(result.contains("25"))
    }

    // MARK: - Int.pluralized

    @Test("pluralized with 1 is singular")
    func pluralizedSingular() {
        #expect(1.pluralized("day") == "1 day")
        #expect(1.pluralized("book") == "1 book")
        #expect(1.pluralized("page") == "1 page")
    }

    @Test("pluralized with 0 is plural")
    func pluralizedZero() {
        #expect(0.pluralized("day") == "0 days")
    }

    @Test("pluralized with > 1 is plural")
    func pluralizedMultiple() {
        #expect(3.pluralized("day") == "3 days")
        #expect(12.pluralized("book") == "12 books")
        #expect(100.pluralized("page") == "100 pages")
    }
}
