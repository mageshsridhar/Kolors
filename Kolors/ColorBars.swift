import SwiftUI

enum ColorFormat: String, CaseIterable, Identifiable {
    case hex = "HEX"
    case rgb = "RGB"

    var id: Self { self }

    func text(for color: RGBColor) -> String { self == .hex ? color.hex : color.rgbText }
}

/// One full-width color, showing its hex and RGB values. Tapping either value copies it.
struct ColorBar: View {
    let color: RGBColor
    var minHeight: CGFloat = 66
    /// Extra space at the bottom, such as for the home indicator.
    var bottomInset: CGFloat = 0

    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var copies = 0
    @State private var copied: ColorFormat?

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    value(.hex)
                    value(.rgb)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 18)
            } else {
                HStack(spacing: 12) {
                    value(.hex).frame(maxWidth: .infinity, alignment: .leading)
                    value(.rgb).frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .sidePadding(20)
        .frame(maxWidth: .infinity, minHeight: minHeight)
        .padding(.bottom, bottomInset)
        .foregroundColor(color.textColor)
        .background(color.color)
        .task(id: copies) {
            guard copied != nil else { return }
            do {
                try await Task.sleep(nanoseconds: 1_500_000_000)
                copied = nil
            } catch {}
        }
    }

    private func value(_ format: ColorFormat) -> some View {
        let text = format.text(for: color)
        let isHex = format == .hex
        // The copied note replaces the RGB value, wherever the tap was.
        let showsCopied = !isHex && copied != nil
        return Button { copy(format) } label: {
            Group {
                if showsCopied {
                    Label("Copied", systemImage: "checkmark")
                        .font(.geist(.semibold, size: 16, relativeTo: .callout))
                } else {
                    Text(text)
                        .font(isHex
                              ? .geist(.semibold, size: 24, relativeTo: .title2)
                              : .geist(.regular, size: 16, relativeTo: .callout))
                        .tracking(isHex ? -0.4 : 0)
                        .monospacedDigit()
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(copied == format ? "Copied \(text)" : "Copy \(format.rawValue) \(text)")
    }

    private func copy(_ format: ColorFormat) {
        let text = format.text(for: color)
        UIPasteboard.general.string = text
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        UIAccessibility.post(notification: .announcement, argument: "Copied \(text)")
        copied = format
        copies += 1
    }
}

/// The palette as one horizontal strip.
struct PaletteStrip: View {
    let colors: [RGBColor]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                color.color
            }
        }
        .accessibilityHidden(true)
    }
}

extension Array where Element == RGBColor {
    var countLabel: String { count == 1 ? "1 color" : "\(count) colors" }
}

struct ColorBars_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            ForEach(SampleArtwork.palette, id: \.self) { ColorBar(color: $0) }
        }
    }
}
