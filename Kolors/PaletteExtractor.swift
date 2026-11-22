import UIKit
import ColorThiefSwift

enum PaletteExtractor {
    private static let maxPixels: CGFloat = 256
    /// Clusters smaller than this share of the counted pixels are dropped.
    private static let minimumShare = 0.005
    /// Colors whose channels all differ by at most this much count as the same color.
    private static let duplicateTolerance = 4

    /// Returns up to `colorCount` colors, each the average of similar pixels. Simple images return fewer.
    /// CPU-bound: call this off the main thread.
    static func palette(from image: UIImage, colorCount: Int = 5) -> [RGBColor] {
        guard let small = ImageProcessing.resized(image, maxPixels: maxPixels),
              let pixels = rgbPixels(of: small),
              let candidates = ColorThief.getPalette(from: small, colorCount: colorCount, quality: 1),
              !candidates.isEmpty else {
            return []
        }
        // ColorThief ignores white, so do the same here unless the image is nothing but white.
        let nonWhite = pixels.filter { !isWhite($0) }
        return refine(
            candidates.map { RGBColor(red: $0.r, green: $0.g, blue: $0.b) },
            using: nonWhite.isEmpty ? pixels : nonWhite
        )
    }

    /// ColorThief pads simple images with averages of empty color boxes. Assigning every pixel to its
    /// nearest candidate drops those, and averaging the assigned pixels undoes its 5-bit rounding.
    private static func refine(_ candidates: [RGBColor], using pixels: [RGBColor]) -> [RGBColor] {
        struct Cluster {
            var count = 0, red = 0, green = 0, blue = 0
            var average: RGBColor {
                RGBColor(
                    red: UInt8((red + count / 2) / count),
                    green: UInt8((green + count / 2) / count),
                    blue: UInt8((blue + count / 2) / count)
                )
            }
        }

        var clusters = [Cluster](repeating: Cluster(), count: candidates.count)
        for pixel in pixels {
            var nearest = 0
            var nearestDistance = Int.max
            for (index, candidate) in candidates.enumerated() {
                let distance = squaredDistance(pixel, candidate)
                if distance < nearestDistance {
                    nearest = index
                    nearestDistance = distance
                }
            }
            clusters[nearest].count += 1
            clusters[nearest].red += Int(pixel.red)
            clusters[nearest].green += Int(pixel.green)
            clusters[nearest].blue += Int(pixel.blue)
        }

        let minimumCount = max(1, Int(Double(pixels.count) * minimumShare))
        var result = [RGBColor]()
        for cluster in clusters where cluster.count >= minimumCount {
            let color = cluster.average
            if !result.contains(where: { isDuplicate($0, color) }) {
                result.append(color)
            }
        }
        return result
    }

    private static func rgbPixels(of image: UIImage) -> [RGBColor]? {
        guard let cgImage = image.cgImage, let space = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                bytesPerRow: width * 4, space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            ) else { return false }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return nil }
        return stride(from: 0, to: bytes.count, by: 4).map {
            RGBColor(red: bytes[$0], green: bytes[$0 + 1], blue: bytes[$0 + 2])
        }
    }

    /// Same threshold ColorThief uses.
    private static func isWhite(_ color: RGBColor) -> Bool {
        color.red > 250 && color.green > 250 && color.blue > 250
    }

    private static func squaredDistance(_ a: RGBColor, _ b: RGBColor) -> Int {
        let red = Int(a.red) - Int(b.red)
        let green = Int(a.green) - Int(b.green)
        let blue = Int(a.blue) - Int(b.blue)
        return red * red + green * green + blue * blue
    }

    private static func isDuplicate(_ a: RGBColor, _ b: RGBColor) -> Bool {
        abs(Int(a.red) - Int(b.red)) <= duplicateTolerance
            && abs(Int(a.green) - Int(b.green)) <= duplicateTolerance
            && abs(Int(a.blue) - Int(b.blue)) <= duplicateTolerance
    }
}
