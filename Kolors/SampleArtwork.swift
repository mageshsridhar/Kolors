import SwiftUI

/// A drawn sunset above its own palette, to show what the app does.
struct SampleArtwork: View {
    static let palette = [
        RGBColor(red: 255, green: 179, blue: 138),
        RGBColor(red: 255, green: 233, blue: 168),
        RGBColor(red: 226, green: 98, blue: 108),
        RGBColor(red: 126, green: 64, blue: 124),
        RGBColor(red: 45, green: 42, blue: 92)
    ]

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { proxy in
                ZStack {
                    Self.palette[0].color
                    Circle()
                        .fill(Self.palette[1].color)
                        .frame(width: proxy.size.height * 0.5)
                        .position(x: proxy.size.width * 0.66, y: proxy.size.height * 0.44)
                    Hill(left: 0.62, right: 0.50, lift: 0.22).fill(Self.palette[2].color)
                    Hill(left: 0.66, right: 0.74, lift: 0.14).fill(Self.palette[3].color)
                    Hill(left: 0.90, right: 0.80, lift: 0.10).fill(Self.palette[4].color)
                }
            }
            .frame(height: 220)
            .clipped()
            PaletteStrip(colors: Self.palette).frame(height: 56)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement()
        .accessibilityLabel("Example: a sunset picture above the five colors found in it")
        .accessibilityAddTraits(.isImage)
    }
}

private struct Hill: Shape {
    let left: CGFloat
    let right: CGFloat
    let lift: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.height * left))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.height * right),
            control1: CGPoint(x: rect.width * 0.35, y: rect.height * (left - lift)),
            control2: CGPoint(x: rect.width * 0.65, y: rect.height * (right + lift))
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
