import SwiftUI

struct CatchUpCarousel: View {
    let missedDays: [Date]
    let onAnswer: (Date, Bool) -> Void
    let onSkip: () -> Void

    @State private var currentIndex: Int = 0
    @State private var offset: CGFloat = 0
    @State private var flyDirection: FlyDirection?

    private static let greetings = [
        "Welcome back! Let's catch up.",
        "Hey there! Let's see how your week went.",
        "Welcome back! Your book missed you.",
        "No pressure — just checking in.",
    ]

    var body: some View {
        VStack(spacing: 20) {
            // Greeting
            Text(Self.greetings.randomElement()!)
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Card stack
            if currentIndex < missedDays.count {
                let date = missedDays[currentIndex]

                CatchUpCard(date: date)
                    .offset(x: offset)
                    .rotationEffect(.degrees(Double(offset) / 20))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = value.translation.width
                            }
                            .onEnded { value in
                                let threshold: CGFloat = 100
                                if value.translation.width > threshold {
                                    // Swipe right = Yes
                                    flyAway(.right, date: date, didRead: true)
                                } else if value.translation.width < -threshold {
                                    // Swipe left = No
                                    flyAway(.left, date: date, didRead: false)
                                } else {
                                    // Snap back
                                    withAnimation(.spring(response: 0.3)) {
                                        offset = 0
                                    }
                                }
                            }
                    )
                    .animation(.spring(response: 0.3), value: offset)

                // Swipe hints
                HStack {
                    Label("No", systemImage: "xmark")
                        .foregroundStyle(.secondary)
                        .opacity(offset < -30 ? 1 : 0.5)

                    Spacer()

                    Label("Yes", systemImage: "checkmark")
                        .foregroundStyle(.green)
                        .opacity(offset > 30 ? 1 : 0.5)
                }
                .font(.subheadline)
                .padding(.horizontal, 40)

                // Progress dots
                HStack(spacing: 6) {
                    ForEach(0..<missedDays.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? Color.primary : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }

            // Skip button
            Button("Skip catch-up") {
                onSkip()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding()
    }

    private func flyAway(_ direction: FlyDirection, date: Date, didRead: Bool) {
        let flyOffset: CGFloat = direction == .right ? 500 : -500
        withAnimation(.easeIn(duration: 0.3)) {
            offset = flyOffset
        }
        HapticManager.swipe()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onAnswer(date, didRead)
            currentIndex += 1
            offset = 0
        }
    }

    private enum FlyDirection {
        case left, right
    }
}

// MARK: - Catch-Up Card

struct CatchUpCard: View {
    let date: Date

    var body: some View {
        VStack(spacing: 16) {
            Text(date.friendlyDayString)
                .font(.headline)

            Text("Did you read?")
                .font(.title3)
                .fontWeight(.medium)

            HStack(spacing: 32) {
                VStack {
                    Image(systemName: "arrow.left")
                        .font(.caption)
                    Text("No")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)

                VStack {
                    Image(systemName: "arrow.right")
                        .font(.caption)
                    Text("Yes")
                        .font(.caption)
                }
                .foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 8, y: 4)
        .padding(.horizontal, 24)
    }
}

#Preview {
    let calendar = Calendar.current
    let today = Date()
    let missedDays = (1...3).compactMap {
        calendar.date(byAdding: .day, value: -$0, to: today)
    }.reversed()

    CatchUpCarousel(
        missedDays: Array(missedDays),
        onAnswer: { date, didRead in
            print("\(date): \(didRead)")
        },
        onSkip: {
            print("Skipped")
        }
    )
}
