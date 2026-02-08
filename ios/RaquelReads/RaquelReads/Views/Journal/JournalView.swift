import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyCheckIn.date, order: .reverse) private var checkIns: [DailyCheckIn]
    @State private var selectedDate: Date = Date()
    @State private var displayedMonth: Date = Date()

    private let calendar = Calendar.current

    private var readingDates: Set<Date> {
        Set(checkIns.filter(\.didRead).map(\.date))
    }

    private var daysInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: monthStart)
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private var firstWeekdayOffset: Int {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else {
            return 0
        }
        // Sunday = 1, we want Monday = 0
        let weekday = calendar.component(.weekday, from: monthStart)
        return (weekday + 5) % 7
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Month navigation
                    HStack {
                        Button {
                            changeMonth(by: -1)
                        } label: {
                            Image(systemName: "chevron.left")
                        }

                        Spacer()

                        Text(monthTitle)
                            .font(.headline)

                        Spacer()

                        Button {
                            changeMonth(by: 1)
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                    }
                    .padding(.horizontal)

                    // Weekday headers
                    let weekdays = ["M", "T", "W", "T", "F", "S", "S"]
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(weekdays, id: \.self) { day in
                            Text(day)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }

                        // Empty cells for offset
                        ForEach(0..<firstWeekdayOffset, id: \.self) { _ in
                            Color.clear
                                .frame(height: 40)
                        }

                        // Day cells
                        ForEach(daysInMonth, id: \.self) { date in
                            DayCell(
                                date: date,
                                isToday: date.isToday,
                                didRead: readingDates.contains(date.startOfDay),
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate)
                            )
                            .onTapGesture {
                                selectedDate = date
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Selected day detail
                    if let checkIn = checkIns.first(where: { calendar.isDate($0.date, inSameDayAs: selectedDate) }) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(selectedDate.friendlyDayString)
                                    .font(.headline)
                                Spacer()
                                Image(systemName: checkIn.didRead ? "checkmark.circle.fill" : "xmark.circle")
                                    .foregroundStyle(checkIn.didRead ? .green : .secondary)
                            }

                            Text(checkIn.didRead ? "You read this day!" : "No reading logged")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Journal")
        }
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            withAnimation {
                displayedMonth = newMonth
            }
        }
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let isToday: Bool
    let didRead: Bool
    let isSelected: Bool

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
            }

            VStack(spacing: 4) {
                Text(dayNumber)
                    .font(.subheadline)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(isToday ? .accentColor : .primary)

                Circle()
                    .fill(didRead ? Color.green : Color.clear)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(height: 40)
    }
}

#Preview {
    JournalView()
        .modelContainer(for: DailyCheckIn.self, inMemory: true)
}
