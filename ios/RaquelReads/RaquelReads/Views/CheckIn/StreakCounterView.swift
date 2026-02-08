import SwiftUI

struct StreakCounterView: View {
    let currentStreak: Int
    let bestStreak: Int
    let readingDaysThisWeek: Int

    @State private var animatedStreak: Int = 0
    @State private var flameScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 16) {
            // Main streak display
            HStack(spacing: 8) {
                Image(systemName: currentStreak > 0 ? "flame.fill" : "flame")
                    .font(.system(size: 32))
                    .foregroundStyle(currentStreak > 0 ? .orange : .secondary)
                    .scaleEffect(flameScale)
                    .symbolEffect(.bounce, value: currentStreak)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(animatedStreak)-day streak")
                        .font(.title2)
                        .fontWeight(.bold)
                        .contentTransition(.numericText())

                    if currentStreak > 0 && currentStreak == bestStreak {
                        Text("Personal best!")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .fontWeight(.medium)
                    }
                }
            }

            // Weekly summary
            HStack(spacing: 20) {
                StatPill(
                    icon: "calendar",
                    value: "\(readingDaysThisWeek)",
                    label: "this week"
                )

                if bestStreak > currentStreak {
                    StatPill(
                        icon: "trophy.fill",
                        value: "\(bestStreak)",
                        label: "best streak"
                    )
                }
            }
        }
        .onAppear {
            animatedStreak = currentStreak
        }
        .onChange(of: currentStreak) { _, newValue in
            // Animate flame on streak change
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                flameScale = 1.3
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    flameScale = 1.0
                }
            }

            withAnimation(.snappy) {
                animatedStreak = newValue
            }
        }
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.semibold)
            Text(label)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

#Preview {
    StreakCounterView(
        currentStreak: 12,
        bestStreak: 15,
        readingDaysThisWeek: 4
    )
}
