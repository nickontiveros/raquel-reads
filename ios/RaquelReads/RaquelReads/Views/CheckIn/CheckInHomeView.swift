import SwiftUI
import SwiftData

struct CheckInHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: CheckInViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    CheckInContent(viewModel: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Raquel Reads")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = CheckInViewModel(modelContext: modelContext)
            }
            viewModel?.refresh()
        }
    }
}

// MARK: - Content

private struct CheckInContent: View {
    @Bindable var viewModel: CheckInViewModel

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Catch-up flow (if missed days exist)
                    if viewModel.showCatchUp {
                        CatchUpCarousel(
                            missedDays: viewModel.missedDays,
                            onAnswer: { date, didRead in
                                viewModel.catchUp(date: date, didRead: didRead)
                            },
                            onSkip: {
                                viewModel.skipCatchUp()
                            }
                        )
                    } else {
                        // Normal check-in flow
                        Spacer()
                            .frame(height: 20)

                        // Streak counter
                        StreakCounterView(
                            currentStreak: viewModel.currentStreak,
                            bestStreak: viewModel.bestStreak,
                            readingDaysThisWeek: viewModel.readingDaysThisWeek
                        )

                        // The big button
                        CheckInButton(hasCheckedIn: viewModel.hasCheckedInToday) {
                            viewModel.checkInToday()
                        }
                        .padding(.horizontal, 24)

                        // Encouraging message
                        EncouragingMessage(
                            message: viewModel.celebrationService.encouragingMessage
                        )

                        // Optional detail cards (below the fold)
                        if viewModel.hasCheckedInToday {
                            OptionalDetailsSection()
                        }
                    }
                }
                .padding(.bottom, 40)
            }

            // Celebration overlay (confetti + milestone)
            CelebrationOverlay(
                showConfetti: Bindable(viewModel.celebrationService).showConfetti,
                milestone: viewModel.celebrationService.currentMilestone,
                showMilestone: Bindable(viewModel.celebrationService).showMilestone
            )
        }
    }
}

// MARK: - Optional Details

private struct OptionalDetailsSection: View {
    var body: some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.horizontal)

            Text("Add details")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                DetailCard(
                    icon: "book.fill",
                    title: "What I read",
                    subtitle: "Attach a book"
                )

                DetailCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "How far I got",
                    subtitle: "Log pages"
                )
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Detail Card

private struct DetailCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        Button {
            // TODO: Open detail entry flow
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.accentColor)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CheckInHomeView()
        .modelContainer(for: [
            DailyCheckIn.self,
            StreakRecord.self,
            Book.self,
            ReadingSession.self,
            Goal.self,
            UserSettings.self,
        ], inMemory: true)
}
