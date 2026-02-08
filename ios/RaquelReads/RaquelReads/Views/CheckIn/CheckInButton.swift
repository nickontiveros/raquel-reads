import SwiftUI

struct CheckInButton: View {
    let hasCheckedIn: Bool
    let action: () -> Void

    @State private var isPressed = false
    @State private var checkmarkScale: CGFloat = 0
    @State private var glowOpacity: Double = 0

    var body: some View {
        Button(action: {
            if !hasCheckedIn {
                action()
            }
        }) {
            ZStack {
                // Background glow when checked in
                if hasCheckedIn {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            RadialGradient(
                                colors: [.green.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 120
                            )
                        )
                        .opacity(glowOpacity)
                }

                RoundedRectangle(cornerRadius: 24)
                    .fill(hasCheckedIn ? Color.green : Color.accentColor)
                    .shadow(color: (hasCheckedIn ? Color.green : Color.accentColor).opacity(0.4),
                            radius: isPressed ? 4 : 12,
                            y: isPressed ? 2 : 6)

                if hasCheckedIn {
                    // Checked-in state
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                            .scaleEffect(checkmarkScale)
                        Text("You read today!")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                } else {
                    // Ready to check in
                    HStack(spacing: 12) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 24))
                        Text("I read today")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                }
            }
            .frame(height: 80)
        }
        .buttonStyle(CheckInButtonStyle())
        .disabled(hasCheckedIn)
        .onChange(of: hasCheckedIn) { _, checked in
            if checked {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    checkmarkScale = 1.0
                }
                withAnimation(.easeIn(duration: 0.8)) {
                    glowOpacity = 1.0
                }
            }
        }
        .onAppear {
            if hasCheckedIn {
                checkmarkScale = 1.0
                glowOpacity = 1.0
            }
        }
    }
}

// MARK: - Button Style

struct CheckInButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 24) {
        CheckInButton(hasCheckedIn: false) {
            print("Checked in!")
        }
        CheckInButton(hasCheckedIn: true) {
            print("Already checked in")
        }
    }
    .padding()
}
