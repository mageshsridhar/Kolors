import SwiftUI

enum Theme {
    static let background = Color(.systemBackground)
    static let fill = Color(.secondarySystemFill)
    /// Meets 4.5:1 on the backgrounds above, which the system's secondary label doesn't.
    static let secondaryText = Color("SecondaryText")
}

/// Whether part of a photo is light or dark, so text and the status bar on it can take the opposite color.
/// A faint fade and a soft shadow, both in the opposite color, keep text readable on busy photos.
enum PhotoTone: Equatable {
    case light, dark

    /// Light enough that black text reads better than white.
    private static let lightLuminance = 0.3

    /// The average tone of the top or bottom quarter of an image.
    static func of(_ image: UIImage, top: Bool) -> PhotoTone {
        guard let cgImage = image.cgImage, let space = CGColorSpace(name: CGColorSpace.sRGB) else { return .dark }
        let side = 16
        var bytes = [UInt8](repeating: 0, count: side * side * 4)
        let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: side, height: side, bitsPerComponent: 8,
                bytesPerRow: side * 4, space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            ) else { return false }
            context.interpolationQuality = .medium
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: side, height: side))
            return true
        }
        guard drawn else { return .dark }
        // Bitmap rows run from the top of the image.
        let rows = top ? 0..<(side / 4) : (side - side / 4)..<side
        var total = 0.0
        for row in rows {
            for column in 0..<side {
                let offset = (row * side + column) * 4
                total += RGBColor(red: bytes[offset], green: bytes[offset + 1], blue: bytes[offset + 2]).luminance
            }
        }
        return total / Double(rows.count * side) > lightLuminance ? .light : .dark
    }

    var textColor: Color { self == .light ? .black : .white }

    /// The opposite of the text color.
    var backdrop: Color { self == .light ? .white : .black }

    /// A faint fade from one edge of a photo.
    func scrim(fromTop: Bool) -> LinearGradient {
        LinearGradient(
            colors: [backdrop.opacity(self == .light ? 0.4 : 0.32), backdrop.opacity(0)],
            startPoint: fromTop ? .top : .bottom, endPoint: fromTop ? .bottom : .top
        )
    }
}

/// A palette's name on its photo.
struct PhotoNameLabel: View {
    let name: String
    let tone: PhotoTone
    var size: CGFloat = 36
    var style: Font.TextStyle = .largeTitle

    var body: some View {
        Text(name)
            .font(.geist(.semibold, size: size, relativeTo: style))
            .tracking(-size / 30)
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .foregroundColor(tone.textColor)
            .shadow(color: tone.backdrop.opacity(0.35), radius: 10)
    }
}

/// Geist, bundled under the SIL Open Font License (see Fonts/OFL.txt). It scales with Dynamic Type.
enum Geist: String {
    case regular = "Geist-Regular"
    case medium = "Geist-Medium"
    case semibold = "Geist-SemiBold"
}

extension Font {
    static func geist(_ weight: Geist, size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        .custom(weight.rawValue, size: size, relativeTo: style)
    }

    static let geistBody = geist(.regular, size: 17, relativeTo: .body)
    static let geistButton = geist(.semibold, size: 17, relativeTo: .body)
}

extension UIFont {
    static func geist(_ weight: Geist, size: CGFloat) -> UIFont {
        UIFont(name: weight.rawValue, size: size) ?? .systemFont(ofSize: size, weight: weight == .regular ? .regular : .semibold)
    }
}

/// Full-width capsule. The primary style is ink, so photos and palettes are the only strong colors on screen.
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
                .font(.geistButton)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, minHeight: 54)
                .foregroundColor(isFilled ? Color(.systemBackground) : (isEnabled ? Color.primary : Theme.secondaryText))
                .background(Capsule().fill(isFilled ? Color.accentColor : Theme.fill))
                .opacity(configuration.isPressed ? 0.7 : 1)
                .contentShape(Capsule())
        }
    }
}

/// A round icon button, the same height as a capsule button.
struct CircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(.primary)
            .frame(width: 54, height: 54)
            .background(Circle().fill(Theme.fill))
            .opacity(configuration.isPressed ? 0.7 : 1)
            .contentShape(Circle())
    }
}

/// An icon for the navigation bar over a photo. iOS 26 draws its own glass; earlier versions get a light circle.
struct BarIcon: View {
    let title: String
    let systemImage: String

    var body: some View {
        if #available(iOS 26, *) {
            Label(title, systemImage: systemImage)
        } else {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.white.opacity(0.85)))
                .accessibilityLabel(title)
        }
    }
}

/// The navigation bar's text button over a photo, such as Save.
struct BarTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Label(configuration: configuration)
    }

    private struct Label: View {
        let configuration: Configuration
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.geistButton)
                .foregroundColor(isEnabled ? Color(.systemBackground) : .black)
                .padding(.horizontal, 18)
                .frame(minHeight: 40)
                .background(Capsule().fill(isEnabled ? Color.accentColor : Color.white.opacity(0.85)))
                .opacity(configuration.isPressed ? 0.7 : 1)
                .fixedSize()
        }
    }
}

/// Swaps between NavigationStack, which iOS 16 added, and NavigationView.
struct NavigationContainer<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        if #available(iOS 16, *) {
            NavigationStack(root: content)
        } else {
            NavigationView(content: content).navigationViewStyle(.stack)
        }
    }
}

extension View {
    /// A screen drawn edge to edge under a see-through navigation bar.
    /// `lightStatusBar` turns the status bar white, for screens with a photo at the top.
    func photoScreen(title: String, lightStatusBar: Bool) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // The title only labels the next screen's back button.
                ToolbarItem(placement: .principal) { Color.clear.frame(width: 1, height: 1) }
            }
            .modifier(BarColorScheme(isDark: lightStatusBar))
    }

    /// Hides iOS 26's fade under the navigation bar, for screens that draw their own over a photo.
    @ViewBuilder func noTopScrollEdgeEffect() -> some View {
        if #available(iOS 26, *) {
            scrollEdgeEffectHidden(true, for: .top)
        } else {
            self
        }
    }

    /// Zooms a pushed screen out of the view it came from, on iOS 18 and later.
    @ViewBuilder func zoomSource(id: AnyHashable, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18, *) {
            matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }

    @ViewBuilder func zoomDestination(id: AnyHashable, in namespace: Namespace.ID?) -> some View {
        if #available(iOS 18, *), let namespace = namespace {
            navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            self
        }
    }
}

private struct BarColorScheme: ViewModifier {
    let isDark: Bool

    func body(content: Content) -> some View {
        if #available(iOS 16, *) {
            content
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbarColorScheme(isDark ? .dark : .light, for: .navigationBar)
        } else {
            content
        }
    }
}

/// The safe area at the sides, for text on screens whose photos and colors run edge to edge in landscape.
struct SideInsets: Equatable {
    var leading: CGFloat = 0
    var trailing: CGFloat = 0
}

private struct SideInsetsKey: EnvironmentKey {
    static let defaultValue = SideInsets()
}

extension EnvironmentValues {
    var sideInsets: SideInsets {
        get { self[SideInsetsKey.self] }
        set { self[SideInsetsKey.self] = newValue }
    }
}

extension View {
    /// Horizontal padding that also keeps clear of the sides' safe area.
    func sidePadding(_ length: CGFloat) -> some View {
        modifier(SidePadding(length: length))
    }

    /// Runs edge to edge at the sides, telling text inside how far to stay in.
    func edgeToEdgeSides(_ proxy: GeometryProxy) -> some View {
        environment(\.sideInsets, SideInsets(leading: proxy.safeAreaInsets.leading, trailing: proxy.safeAreaInsets.trailing))
    }
}

private struct SidePadding: ViewModifier {
    let length: CGFloat
    @Environment(\.sideInsets) private var insets

    func body(content: Content) -> some View {
        content
            .padding(.leading, length + insets.leading)
            .padding(.trailing, length + insets.trailing)
    }
}

enum NavigationBarStyle {
    /// See-through on every screen, including on iOS 15, where `toolbarBackground` isn't available.
    static func apply() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}
