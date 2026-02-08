import Foundation

extension Date {
    /// Returns the start of day for this date
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Returns true if this date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Returns true if this date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// Days between this date and another date
    func days(to other: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: self)
        let end = calendar.startOfDay(for: other)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    /// Returns an array of dates from this date to the target (exclusive of target)
    func datesUntil(_ target: Date) -> [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        var current = calendar.startOfDay(for: self)
        let end = calendar.startOfDay(for: target)

        while current < end {
            dates.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return dates
    }

    /// Formatted as "Monday, Feb 4"
    var friendlyDayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: self)
    }

    /// Formatted as "Feb 4"
    var shortDayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }
}

extension Int {
    /// Pluralize a word based on count: 1.pluralized("day") → "1 day", 3.pluralized("day") → "3 days"
    func pluralized(_ word: String) -> String {
        "\(self) \(word)\(self == 1 ? "" : "s")"
    }
}
