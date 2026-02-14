import SwiftUI

/// A button style that provides visual feedback on hover and press.
/// Solves the macOS-specific issue where `.buttonStyle(.plain)` buttons
/// give no visual cue that they're interactive.
struct HoverableButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : isHovered ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.1), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

/// A button style for icon-only buttons that adds a hover background.
struct HoverableIconButtonStyle: ButtonStyle {
    var hoverColor: Color = ExTokens.Colors.backgroundElevated

    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: ExTokens.Radius.sm)
                    .fill(isHovered ? hoverColor : Color.clear)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.1), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension View {
    /// Ensures the view has a minimum hit target of 44x44pt (Apple HIG).
    func minHitTarget(width: CGFloat = 44, height: CGFloat = 44) -> some View {
        self.contentShape(Rectangle())
            .frame(minWidth: width, minHeight: height)
    }
}
