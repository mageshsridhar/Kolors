import UIKit

enum ImageProcessing {
    static let storedMaxPixels: CGFloat = 1200
    static let thumbnailMaxPixels: CGFloat = 120

    /// Redraws the image upright, in 8-bit sRGB, on white, no larger than `maxPixels` on its longest side.
    static func resized(_ image: UIImage, maxPixels: CGFloat) -> UIImage? {
        let width = image.size.width * image.scale
        let height = image.size.height * image.scale
        guard width > 0, height > 0 else { return nil }

        let ratio = min(1, maxPixels / max(width, height))
        let size = CGSize(width: max(1, (width * ratio).rounded()), height: max(1, (height * ratio).rounded()))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        format.preferredRange = .standard

        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// Decodes image data at no more than `maxPixels` on its longest side, without decoding it in full.
    static func downsampled(_ data: Data, maxPixels: CGFloat) -> UIImage? {
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, options) else { return nil }
        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixels
        ] as CFDictionary
        return CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions).map { UIImage(cgImage: $0) }
    }

    static func storedImageData(from image: UIImage) -> Data? {
        resized(image, maxPixels: storedMaxPixels)?.jpegData(compressionQuality: 0.8)
    }

    static func thumbnailData(from image: UIImage) -> Data? {
        resized(image, maxPixels: thumbnailMaxPixels)?.jpegData(compressionQuality: 0.8)
    }
}
