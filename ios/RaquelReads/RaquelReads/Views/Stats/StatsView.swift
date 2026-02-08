import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<DailyCheckIn> { $0.didRead == true }) private var readDays: [DailyCheckIn]
    @Query(filter: #Predicate<Book> { $0.status == .completed }) private var completedBooks: [Book]
    @Query(filter: #Predicate<Goal> { $0.active == true }) private var activeGoals: [Goal]

    @State private var streakService: StreakService?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Streak stats
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: 12) {
                        StatCard(
                            icon: "flame.fill",
                            iconColor: .orange,
                            value: "\(streakService?.currentStreak() ?? 0)",
                            label: "Current Streak"
                        )

                        StatCard(
                            icon: "trophy.fill",
                            iconColor: .yellow,
                            value: "\(streakService?.bestStreak() ?? 0)",
                            label: "Best Streak"
                        )

                        StatCard(
                            icon: "calendar",
                            iconColor: .blue,
                            value: "\(readDays.count)",
                            label: "Total Reading Days"
                        )

                        StatCard(
                            icon: "books.vertical.fill",
                            iconColor: .green,
                            value: "\(completedBooks.count)",
                            label: "Books Completed"
                        )
                    }
                    .padding(.horizontal)

                    // Active goals
                    if !activeGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Active Goals")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(activeGoals) { goal in
                                GoalRow(goal: goal)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    // Placeholder for charts
                    VStack(spacing: 12) {
                        Text("Reading Trends")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.1))
                            .frame(height: 200)
                            .overlay {
                                VStack {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)
                                    Text("Charts coming soon")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .navigationTitle("Statistics")
            .onAppear {
                if streakService == nil {
                    streakService = StreakService(modelContext: modelContext)
                }
            }
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Goal Row

struct GoalRow: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: goal.type.icon)
                    .foregroundStyle(.accentColor)
                Text(goal.type.label)
                    .fontWeight(.medium)
                Spacer()
                Text("0 / \(goal.target)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: 0, total: Double(goal.target))
                .tint(.accentColor)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [DailyCheckIn.self, Book.self, Goal.self], inMemory: true)
}
