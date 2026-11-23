import SwiftUI

/// A drawn sunset, made of exactly the colors in `palette`, to show what the app does.
struct SampleArtwork: View {
    private static let sky = RGBColor(red: 246, green: 166, blue: 139)
    private static let sun = RGBColor(red: 255, green: 226, blue: 160)
    private static let near = RGBColor(red: 217, green: 93, blue: 119)
    private static let middle = RGBColor(red: 124, green: 63, blue: 126)
    private static let far = RGBColor(red: 46, green: 42, blue: 94)

    /// In the order the app finds them, most common first.
    static let palette = [sky, far, near, middle, sun]

    /// The drawing is a 400-point square. It fills the space and is cropped, keeping this
    /// fraction of its height in view.
    private static let size: CGFloat = 400
    private static let verticalAnchor: CGFloat = 0.62

    var body: some View {
        GeometryReader { proxy in
            let scale = max(proxy.size.width, proxy.size.height) / Self.size
            let side = Self.size * scale
            ZStack(alignment: .topLeading) {
                Self.sky.color
                Circle()
                    .fill(Self.sun.color)
                    .frame(width: 116 * scale, height: 116 * scale)
                    .offset(x: 82 * scale, y: 92 * scale)
                Hill(points: [(0, 215), (110, 215), (180, 170), (280, 178), (380, 200), (400, 205)])
                    .fill(Self.near.color)
                Hill(points: [(0, 262), (90, 215), (170, 250), (240, 280), (360, 285), (400, 255)])
                    .fill(Self.middle.color)
                Hill(points: [(0, 318), (70, 330), (120, 352), (190, 335), (320, 290), (400, 330)])
                    .fill(Self.far.color)
            }
            .frame(width: side, height: side)
            .offset(
                x: (proxy.size.width - side) / 2,
                y: (proxy.size.height - side) * Self.verticalAnchor
            )
        }
        .clipped()
        .accessibilityElement()
        .accessibilityLabel("Example: a sunset drawing above the five colors found in it")
        .accessibilityAddTraits(.isImage)
    }
}

/// A hill's top edge on the 400-point square, as two smoothly joined curves, filled to the bottom.
private struct Hill: Shape {
    /// Start, two control points, middle, the second curve's last control point, end.
    /// The second curve's first control point mirrors the first curve's last, so the join is smooth.
    let points: [(CGFloat, CGFloat)]

    func path(in rect: CGRect) -> Path {
        let scale = rect.width / 400
        let point = { (index: Int) in CGPoint(x: points[index].0 * scale, y: points[index].1 * scale) }
        let middle = point(3)
        let mirrored = CGPoint(x: 2 * middle.x - point(2).x, y: 2 * middle.y - point(2).y)
        var path = Path()
        path.move(to: point(0))
        path.addCurve(to: middle, control1: point(1), control2: point(2))
        path.addCurve(to: point(5), control1: mirrored, control2: point(4))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
