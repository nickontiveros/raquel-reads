import SwiftUI

struct CelebrationOverlay: View {
    @Binding var showConfetti: Bool
    var milestone: StreakMilestone?
    @Binding var showMilestone: Bool

    var body: some View {
        ZStack {
            // Confetti particles
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .onAppear {
                        // Auto-dismiss confetti after animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation {
                                showConfetti = false
                            }
                        }
                    }
            }

            // Milestone banner
            if showMilestone, let milestone {
                MilestoneBanner(milestone: milestone) {
                    withAnimation(.spring) {
                        showMilestone = false
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                for particle in particles {
                    let age = now - particle.createdAt
                    guard age < particle.lifetime else { continue }

                    let progress = age / particle.lifetime
                    let x = particle.startX + sin(age * particle.wobbleSpeed) * particle.wobbleAmount
                    let y = particle.startY + age * particle.fallSpeed
                    let opacity = 1.0 - (progress * progress) // Ease out opacity
                    let rotation = Angle.degrees(age * particle.rotationSpeed)

                    context.opacity = opacity
                    context.translateBy(x: x, y: y)
                    context.rotate(by: rotation)

                    let rect = CGRect(
                        x: -particle.size / 2,
                        y: -particle.size / 2,
                        width: particle.size,
                        height: particle.size * particle.aspectRatio
                    )
                    context.fill(
                        Path(roundedRect: rect, cornerRadius: 2),
                        with: .color(particle.color)
                    )

                    context.rotate(by: -rotation)
                    context.translateBy(x: -x, y: -y)
                    context.opacity = 1.0
                }
            }
        }
        .onAppear {
            particles = (0..<80).map { _ in
                ConfettiParticle.random()
            }
        }
    }
}

// MARK: - Confetti Particle

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let startX: CGFloat
    let startY: CGFloat
    let size: CGFloat
    let aspectRatio: CGFloat
    let color: Color
    let fallSpeed: CGFloat
    let wobbleSpeed: Double
    let wobbleAmount: CGFloat
    let rotationSpeed: Double
    let lifetime: Double
    let createdAt: TimeInterval

    static let colors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink, .mint, .teal
    ]

    static func random() -> ConfettiParticle {
        ConfettiParticle(
            startX: CGFloat.random(in: 20...380),
            startY: CGFloat.random(in: -50...(-10)),
            size: CGFloat.random(in: 6...12),
            aspectRatio: CGFloat.random(in: 0.5...2.0),
            color: colors.randomElement()!,
            fallSpeed: CGFloat.random(in: 100...250),
            wobbleSpeed: Double.random(in: 2...6),
            wobbleAmount: CGFloat.random(in: 20...60),
            rotationSpeed: Double.random(in: 60...360),
            lifetime: Double.random(in: 2.0...3.0),
            createdAt: Date.timeIntervalSinceReferenceDate
        )
    }
}

// MARK: - Milestone Banner

struct MilestoneBanner: View {
    let milestone: StreakMilestone
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.fill")
                .font(.system(size: 40))
                .foregroundStyle(.yellow)
                .symbolEffect(.bounce, options: .repeating)

            Text("\(milestone.rawValue)-Day Milestone!")
                .font(.title2)
                .fontWeight(.bold)

            Text(milestone.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Keep Going!") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .padding(24)
        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 20)
        .padding(32)
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            HapticManager.streakMilestone()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.3).ignoresSafeArea()
        CelebrationOverlay(
            showConfetti: .constant(true),
            milestone: .week,
            showMilestone: .constant(true)
        )
    }
}
