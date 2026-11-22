import SwiftUI

enum ColorFormat: String, CaseIterable, Identifiable {
    case hex = "HEX"
    case rgb = "RGB"

    var id: Self { self }

    func text(for color: RGBColor) -> String { self == .hex ? color.hex : color.rgbText }
}

/// The palette as full-width bars. Tapping one copies its value.
struct ColorBars: View {
    let colors: [RGBColor]
    let format: ColorFormat

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                ColorBar(color: color, format: format)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12))
        )
    }
}

private struct ColorBar: View {
    let color: RGBColor
    let format: ColorFormat

    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var copies = 0
    @State private var copied = false

    private var value: String { format.text(for: color) }

    var body: some View {
        Button(action: copy) {
            HStack {
                Text(value)
                    .font(.headline.monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    if !typeSize.isAccessibilitySize {
                        Text(copied ? "Copied" : "Copy")
                    }
                }
                .font(.subheadline)
            }
            .foregroundColor(color.textColor)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(color.color)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(copied ? "Copied \(value)" : "Copy \(value)")
        .task(id: copies) {
            guard copied else { return }
            do {
                try await Task.sleep(nanoseconds: 1_500_000_000)
                copied = false
            } catch {}
        }
    }

    private func copy() {
        UIPasteboard.general.string = value
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        UIAccessibility.post(notification: .announcement, argument: "Copied \(value)")
        copied = true
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

struct ColorBars_Previews: PreviewProvider {
    static var previews: some View {
        ColorBars(colors: SampleArtwork.palette, format: .hex).padding()
    }
}
