import SwiftUI

/// Photo, format switch and color bars, shared by new and saved palettes.
struct PaletteContent: View {
    let image: UIImage?
    /// `nil` while colors are being extracted.
    let colors: [RGBColor]?
    var onReplace: ((PhotoSource) -> Void)?

    @AppStorage("colorFormat") private var format = ColorFormat.hex

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 14) {
                if let image = image {
                    photo(image)
                }
                palette
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
    }

    private func photo(_ image: UIImage) -> some View {
        Color.clear
            .frame(height: 200)
            .overlay(Image(uiImage: image).resizable().aspectRatio(contentMode: .fill))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .accessibilityElement()
            .accessibilityLabel("Source photo")
            .accessibilityAddTraits(.isImage)
            .overlay(replaceButton, alignment: .bottomTrailing)
    }

    @ViewBuilder private var replaceButton: some View {
        if let onReplace = onReplace {
            Group {
                if PhotoSource.isCameraAvailable {
                    Menu {
                        Button { onReplace(.library) } label: { Label("Choose Photo", systemImage: "photo") }
                        Button { onReplace(.camera) } label: { Label("Take Photo", systemImage: "camera") }
                    } label: {
                        replaceLabel
                    }
                } else {
                    Button { onReplace(.library) } label: { replaceLabel }
                }
            }
            .accessibilityLabel("Replace photo")
            .padding(10)
        }
    }

    private var replaceLabel: some View {
        Text("Replace")
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .background(Capsule().fill(Color.black.opacity(0.72)))
    }

    @ViewBuilder private var palette: some View {
        if let colors = colors {
            if colors.isEmpty {
                Text("No colors could be found in this photo.")
                    .foregroundColor(Theme.secondaryText)
                    .padding(.vertical, 40)
            } else {
                HStack {
                    Text(colors.countLabel).font(.headline)
                    Spacer()
                    Picker("Color format", selection: $format) {
                        ForEach(ColorFormat.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                }
                ColorBars(colors: colors, format: format)
            }
        } else {
            ProgressView("Finding colors")
                .padding(.vertical, 40)
        }
    }
}

extension Array where Element == RGBColor {
    var countLabel: String { count == 1 ? "1 color" : "\(count) colors" }
}
