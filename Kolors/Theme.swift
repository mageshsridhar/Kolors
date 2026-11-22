import SwiftUI

enum Theme {
    static let background = Color(.systemGroupedBackground)
    static let card = Color(.secondarySystemGroupedBackground)
    static let fill = Color(.systemGray5)
    /// Meets 4.5:1 on every background above, which the system's secondary label doesn't.
    static let secondaryText = Color("SecondaryText")
    static let cornerRadius: CGFloat = 22
}

/// Full-width capsule. The primary style is ink, so the photo's colors are the only strong colors on screen.
struct CapsuleButtonStyle: ButtonStyle {
    var isPrimary = true

    func makeBody(configuration: Configuration) -> some View {
        CapsuleLabel(configuration: configuration, isPrimary: isPrimary)
    }

    private struct CapsuleLabel: View {
        let configuration: Configuration
        let isPrimary: Bool
        @Environment(\.isEnabled) private var isEnabled

        private var isFilled: Bool { isPrimary && isEnabled }

        var body: some View {
            configuration.label
                .font(.headline)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, minHeight: 50)
                .foregroundColor(isFilled ? Color(.systemBackground) : (isEnabled ? Color.primary : Theme.secondaryText))
                .background(Capsule().fill(isFilled ? Color.accentColor : Theme.fill))
                .opacity(configuration.isPressed ? 0.7 : 1)
                .contentShape(Capsule())
        }
    }
}

extension View {
    /// Pins an action to the bottom of a screen.
    func bottomDock<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        let dock = content()
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Theme.background.ignoresSafeArea())
            .overlay(Divider(), alignment: .top)
        return safeAreaInset(edge: .bottom, spacing: 0) { dock }
    }

    @ViewBuilder func tabBarHidden() -> some View {
        if #available(iOS 16, *) {
            toolbar(.hidden, for: .tabBar)
        } else {
            self
        }
    }
}
