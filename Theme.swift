import SwiftUI

enum AITheme {
    static let gradient = LinearGradient(
        colors: [
            Color(red: 0.46, green: 0.29, blue: 0.96),
            Color(red: 0.07, green: 0.56, blue: 0.99),
            Color(red: 0.00, green: 0.86, blue: 0.72)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct GradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AITheme.gradient)
                    .opacity(configuration.isPressed ? 0.85 : 1.0)
            )
            .foregroundStyle(.white)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
