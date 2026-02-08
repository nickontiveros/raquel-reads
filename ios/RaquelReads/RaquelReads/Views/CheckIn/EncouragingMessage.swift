import SwiftUI

struct EncouragingMessage: View {
    let message: String

    @State private var opacity: Double = 0
    @State private var offset: CGFloat = 10

    var body: some View {
        if !message.isEmpty {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .opacity(opacity)
                .offset(y: offset)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                        opacity = 1.0
                        offset = 0
                    }
                }
                .onChange(of: message) { _, _ in
                    // Reset and re-animate on message change
                    opacity = 0
                    offset = 10
                    withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                        opacity = 1.0
                        offset = 0
                    }
                }
        }
    }
}

#Preview {
    EncouragingMessage(message: "You showed up for yourself today.")
}
