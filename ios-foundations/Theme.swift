import SwiftUI

enum AITheme {
    static let gradient: Color = .accentColor
}

struct GradientButtonStyle: ButtonStyle {
    var isAnimating: Bool = false

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
