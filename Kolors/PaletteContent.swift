import SwiftUI

/// The photo above full-width color bars, shared by new and saved palettes.
struct PaletteContent: View {
    /// Labels the next screen's back button.
    let title: String
    let image: UIImage?
    /// `nil` while colors are being extracted.
    let colors: [RGBColor]?
    /// Shown on the photo once the palette has one.
    var name: String?

    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var topTone = PhotoTone.dark
    @State private var bottomTone = PhotoTone.dark

    var body: some View {
        GeometryReader { proxy in
            let insets = proxy.safeAreaInsets
            let height = proxy.size.height + insets.top + insets.bottom
            let photoHeight = (height * (typeSize.isAccessibilitySize ? 0.34 : 0.48)).rounded()
            let barsHeight = height - photoHeight
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    photo(height: photoHeight)
                    palette(height: barsHeight, bottomInset: insets.bottom)
                }
            }
            .bounceOnlyWhenScrollable()
            .noTopScrollEdgeEffect()
            .ignoresSafeArea()
            .edgeToEdgeSides(proxy)
        }
        .background(Theme.background.ignoresSafeArea())
        .photoScreen(title: title, lightStatusBar: topTone == .dark)
        .task(id: image.map(ObjectIdentifier.init)) {
            guard let image = image else { return }
            let tones = await Task.detached(priority: .userInitiated) {
                (top: PhotoTone.of(image, top: true), bottom: PhotoTone.of(image, top: false))
            }.value
            topTone = tones.top
            bottomTone = tones.bottom
        }
    }

    private func photo(height: CGFloat) -> some View {
        Color.black
            .frame(height: height)
            .overlay(image.map { Image(uiImage: $0).resizable().aspectRatio(contentMode: .fill) })
            .clipped()
            .overlay(topTone.scrim(fromTop: true).frame(height: 120), alignment: .top)
            .overlay(nameLabel, alignment: .bottomLeading)
            .overlay(Rectangle().fill(Color.gray.opacity(0.35)).frame(height: 1), alignment: .bottom)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(name.map { "\($0), source photo" } ?? "Source photo")
            .accessibilityAddTraits(.isImage)
    }

    @ViewBuilder private var nameLabel: some View {
        if let name = name {
            PhotoNameLabel(name: name, tone: bottomTone)
                .sidePadding(20)
                .padding(.top, 50)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(bottomTone.scrim(fromTop: false))
                .accessibilityAddTraits(.isHeader)
        }
    }

    @ViewBuilder private func palette(height: CGFloat, bottomInset: CGFloat) -> some View {
        if let colors = colors, !colors.isEmpty {
            let barHeight = max(66, ((height - bottomInset) / CGFloat(colors.count)).rounded(.down))
            VStack(spacing: 0) {
                ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                    ColorBar(
                        color: color, minHeight: barHeight,
                        bottomInset: index == colors.count - 1 ? bottomInset : 0
                    )
                }
            }
        } else {
            Group {
                if colors == nil {
                    ProgressView("Finding colors")
                } else {
                    Text("No colors could be found in this photo.")
                        .foregroundColor(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, minHeight: max(160, height))
        }
    }
}

private extension View {
    @ViewBuilder func bounceOnlyWhenScrollable() -> some View {
        if #available(iOS 16.4, *) {
            scrollBounceBehavior(.basedOnSize)
        } else {
            self
        }
    }
}
