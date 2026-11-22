import LinkPresentation
import SwiftUI

struct SharedPalette: Identifiable {
    let id = UUID()
    let items: [Any]

    init(name: String, image: UIImage?, colors: [RGBColor]) {
        items = [
            ShareImageItem(name: name, image: PaletteShareImage.render(photo: image, colors: colors)),
            ([name] + colors.map(\.hex)).joined(separator: "\n")
        ]
    }
}

/// Shares an image, and previews it with the palette's name in the share sheet.
private final class ShareImageItem: NSObject, UIActivityItemSource {
    private let name: String
    private let image: UIImage

    init(name: String, image: UIImage) {
        self.name = name
        self.image = image
    }

    func activityViewControllerPlaceholderItem(_ controller: UIActivityViewController) -> Any { image }

    func activityViewController(
        _ controller: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        image
    }

    func activityViewControllerLinkMetadata(_ controller: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = name
        metadata.imageProvider = NSItemProvider(object: image)
        return metadata
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

enum PaletteShareImage {
    private static let width: CGFloat = 1080
    private static let photoHeight: CGFloat = 720
    private static let barHeight: CGFloat = 160

    /// The photo above labeled color bars.
    static func render(photo: UIImage?, colors: [RGBColor]) -> UIImage {
        let photoHeight = photo == nil ? 0 : Self.photoHeight
        let size = CGSize(width: width, height: max(1, photoHeight + barHeight * CGFloat(colors.count)))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        format.preferredRange = .standard

        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            if let photo = photo, photo.size.width > 0, photo.size.height > 0 {
                let frame = CGRect(x: 0, y: 0, width: width, height: photoHeight)
                let ratio = max(frame.width / photo.size.width, frame.height / photo.size.height)
                let fitted = CGSize(width: photo.size.width * ratio, height: photo.size.height * ratio)
                context.cgContext.saveGState()
                context.cgContext.clip(to: frame)
                photo.draw(in: CGRect(
                    x: frame.midX - fitted.width / 2, y: frame.midY - fitted.height / 2,
                    width: fitted.width, height: fitted.height
                ))
                context.cgContext.restoreGState()
            }
            for (index, color) in colors.enumerated() {
                let bar = CGRect(x: 0, y: photoHeight + barHeight * CGFloat(index), width: width, height: barHeight)
                UIColor(
                    red: CGFloat(color.red) / 255, green: CGFloat(color.green) / 255,
                    blue: CGFloat(color.blue) / 255, alpha: 1
                ).setFill()
                context.fill(bar)
                let text = NSAttributedString(string: color.hex, attributes: [
                    .font: UIFont.systemFont(ofSize: 48, weight: .semibold),
                    .foregroundColor: color.prefersWhiteText ? UIColor.white : UIColor.black
                ])
                text.draw(at: CGPoint(x: 56, y: bar.midY - text.size().height / 2))
            }
        }
    }
}
