import UIKit

/// Picks the few colors that best represent an image.
///
/// Pixels are grouped by perceptual (OKLab) distance, with as many groups as the image needs, so different colors
/// are never blended together. The groups shown are then chosen for both coverage and contrast, which lets a small
/// vivid accent beat yet another shade of the background.
enum PaletteExtractor {
    private static let maxPixels: CGFloat = 256
    /// Pixels closer than this in OKLab (where black to white is 1) share a group.
    private static let groupRadius = 0.075
    /// Groups closer than this look too similar to show together.
    private static let minimumDistance = 0.06
    /// Groups smaller than this share of the counted pixels are ignored.
    private static let minimumShare = 0.005
    /// How much coverage counts next to contrast. 0 would ignore coverage.
    private static let coverageExponent = 0.4
    /// How much vivid colors are preferred over gray ones.
    private static let vividnessBonus = 2.0
    /// How much a difference in lightness counts next to a difference in hue.
    private static let lightnessWeight = 0.6
    /// Differences between colors darker than this OKLab lightness are increasingly hard to see.
    private static let darkLightness = 0.5
    /// How far from a group's center, in OKLab, a pixel can be and still represent it well.
    private static let representativeSpread = 0.02

    /// Returns up to `colorCount` colors, the most common first. Simple images return fewer.
    /// Every color is the color of a pixel in the image, after scaling it down.
    /// CPU-bound: call this off the main thread.
    static func palette(from image: UIImage, colorCount: Int = 5) -> [RGBColor] {
        guard let small = ImageProcessing.resized(image, maxPixels: maxPixels),
              let bitmap = Bitmap(small) else {
            return []
        }
        return select(colorCount, from: groups(of: countPixels(in: bitmap))).map(\.representative)
    }

    // MARK: - Counting

    private struct PixelCounts {
        /// Every counted pixel, for measuring how much of the image a color covers.
        let covered: [RGBColor: Int]
        /// Leaves out the blended pixels where two colors meet, so a blend can't become a palette color.
        let solid: [RGBColor: Int]
    }

    /// Skips white, which is usually a page or background, unless the image is nothing but white.
    private static func countPixels(in bitmap: Bitmap) -> PixelCounts {
        var all = [RGBColor: Int]()
        var nonWhite = [RGBColor: Int]()
        var solid = [RGBColor: Int]()
        for y in 0..<bitmap.height {
            for x in 0..<bitmap.width {
                let color = bitmap[x, y]
                all[color, default: 0] += 1
                if isWhite(color) { continue }
                nonWhite[color, default: 0] += 1
                if x > 0, x < bitmap.width - 1, isBlend(color, of: bitmap[x - 1, y], and: bitmap[x + 1, y]) { continue }
                if y > 0, y < bitmap.height - 1, isBlend(color, of: bitmap[x, y - 1], and: bitmap[x, y + 1]) { continue }
                solid[color, default: 0] += 1
            }
        }
        let covered = nonWhite.isEmpty ? all : nonWhite
        return PixelCounts(covered: covered, solid: solid.isEmpty ? covered : solid)
    }

    private static func isWhite(_ color: RGBColor) -> Bool {
        color.red > 250 && color.green > 250 && color.blue > 250
    }

    /// Whether `color` is what smoothing an edge between two clearly different neighbors would produce.
    private static func isBlend(_ color: RGBColor, of first: RGBColor, and second: RGBColor) -> Bool {
        let red = Int(second.red) - Int(first.red)
        let green = Int(second.green) - Int(first.green)
        let blue = Int(second.blue) - Int(first.blue)
        let lengthSquared = red * red + green * green + blue * blue
        guard lengthSquared >= 40 * 40 else { return false }

        let redOffset = Int(color.red) - Int(first.red)
        let greenOffset = Int(color.green) - Int(first.green)
        let blueOffset = Int(color.blue) - Int(first.blue)
        let offsetSquared = redOffset * redOffset + greenOffset * greenOffset + blueOffset * blueOffset
        let position = Double(redOffset * red + greenOffset * green + blueOffset * blue) / Double(lengthSquared)
        let strayedSquared = Double(offsetSquared) - position * position * Double(lengthSquared)
        return position > 0.1 && position < 0.9 && strayedSquared < 0.04 * Double(lengthSquared)
    }

    // MARK: - Grouping

    private struct Group {
        let center: OKLab
        let coveredCount: Int
        let solidCount: Int
        let representative: RGBColor
    }

    private struct Sum {
        var lightness = 0.0, a = 0.0, b = 0.0
        var count = 0

        mutating func add(_ color: OKLab, count added: Int) {
            lightness += color.lightness * Double(added)
            a += color.a * Double(added)
            b += color.b * Double(added)
            count += added
        }

        var average: OKLab {
            OKLab(lightness: lightness / Double(count), a: a / Double(count), b: b / Double(count))
        }
    }

    private static func groups(of pixels: PixelCounts) -> [Group] {
        // Sorted so the same image always gives the same palette.
        let colors = pixels.solid
            .map { (rgb: $0.key, lab: OKLab($0.key), count: $0.value, key: sortKey($0.key)) }
            .sorted { $0.key < $1.key }

        // Nearly identical colors are handled together to keep this fast.
        var sums = [Int: Sum]()
        for color in colors {
            let key = Int(color.rgb.red >> 3) << 10 | Int(color.rgb.green >> 3) << 5 | Int(color.rgb.blue >> 3)
            sums[key, default: Sum()].add(color.lab, count: color.count)
        }
        let bins = sums
            .sorted { ($1.value.count, $0.key) < ($0.value.count, $1.key) }
            .map { (lab: $0.value.average, count: $0.value.count) }

        // Each group starts at a common color that no earlier group covers, then settles on its average.
        var centers = [OKLab]()
        for bin in bins where !centers.contains(where: { $0.distance(to: bin.lab) < groupRadius }) {
            centers.append(bin.lab)
        }
        for _ in 0..<5 {
            var totals = [Sum](repeating: Sum(), count: centers.count)
            for bin in bins {
                totals[nearestIndex(to: bin.lab, in: centers)].add(bin.lab, count: bin.count)
            }
            centers = totals.filter { $0.count > 0 }.map(\.average)
        }

        // The average may not be in the image, so show a common color close to it instead.
        var solidCounts = [Int](repeating: 0, count: centers.count)
        var best = [(color: RGBColor, score: Double)?](repeating: nil, count: centers.count)
        for color in colors {
            let index = nearestIndex(to: color.lab, in: centers)
            solidCounts[index] += color.count
            let spread = color.lab.distance(to: centers[index]) / representativeSpread
            let score = log(Double(color.count)) - spread * spread
            if score > best[index]?.score ?? -.infinity {
                best[index] = (color.rgb, score)
            }
        }
        var coveredCounts = [Int](repeating: 0, count: centers.count)
        for (color, count) in pixels.covered {
            coveredCounts[nearestIndex(to: OKLab(color), in: centers)] += count
        }
        return centers.indices.compactMap { index in
            best[index].map {
                Group(center: centers[index], coveredCount: coveredCounts[index], solidCount: solidCounts[index],
                      representative: $0.color)
            }
        }
    }

    private static func sortKey(_ color: RGBColor) -> Int {
        Int(color.red) << 16 | Int(color.green) << 8 | Int(color.blue)
    }

    private static func nearestIndex(to color: OKLab, in centers: [OKLab]) -> Int {
        var nearest = 0
        var nearestDistance = Double.infinity
        for (index, center) in centers.enumerated() {
            let distance = center.squaredDistance(to: color)
            if distance < nearestDistance {
                nearest = index
                nearestDistance = distance
            }
        }
        return nearest
    }

    // MARK: - Choosing

    /// Starts with the most common group, then keeps adding the one that contributes the most.
    private static func select(_ limit: Int, from groups: [Group]) -> [Group] {
        let total = Double(groups.reduce(0) { $0 + $1.coveredCount })
        let solidTotal = Double(groups.reduce(0) { $0 + $1.solidCount })
        var remaining = groups.filter { Double($0.solidCount) / solidTotal >= minimumShare }
        // A very varied image might have no group that large.
        if remaining.isEmpty { remaining = groups }
        guard limit > 0, let first = remaining.indices.max(by: { remaining[$0].coveredCount < remaining[$1].coveredCount }) else {
            return []
        }

        var chosen = [remaining.remove(at: first)]
        while chosen.count < limit {
            remaining.removeAll { group in
                chosen.contains { $0.center.distance(to: group.center) < minimumDistance }
            }
            let scores = remaining.map { group -> Double in
                let nearestContrast = chosen.map { contrast($0.center, group.center) }.min() ?? 0
                let coverage = pow(Double(group.coveredCount) / total, coverageExponent)
                let vividness = group.center.chroma * visibility(atLightness: group.center.lightness)
                return coverage * nearestContrast * (1 + vividnessBonus * vividness)
            }
            guard let best = scores.indices.max(by: { scores[$0] < scores[$1] }) else { break }
            chosen.append(remaining.remove(at: best))
        }
        return chosen.sorted { $0.coveredCount > $1.coveredCount }
    }

    /// How different two colors look side by side, favoring hue over lightness.
    private static func contrast(_ first: OKLab, _ second: OKLab) -> Double {
        let lightness = (first.lightness - second.lightness) * lightnessWeight
        let a = first.a - second.a
        let b = first.b - second.b
        return (lightness * lightness + a * a + b * b).squareRoot()
            * visibility(atLightness: (first.lightness + second.lightness) / 2)
    }

    private static func visibility(atLightness lightness: Double) -> Double {
        min(1, max(0, lightness) / darkLightness)
    }
}

/// An image's pixels in 8-bit sRGB.
private struct Bitmap {
    let width: Int
    let height: Int
    private let bytes: [UInt8]

    init?(_ image: UIImage) {
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
        self.width = width
        self.height = height
        self.bytes = bytes
    }

    subscript(x: Int, y: Int) -> RGBColor {
        let offset = (y * width + x) * 4
        return RGBColor(red: bytes[offset], green: bytes[offset + 1], blue: bytes[offset + 2])
    }
}

/// A color in OKLab, where equal distances look about equally different.
private struct OKLab {
    let lightness: Double
    let a: Double
    let b: Double

    init(lightness: Double, a: Double, b: Double) {
        self.lightness = lightness
        self.a = a
        self.b = b
    }

    init(_ color: RGBColor) {
        let red = Self.linear[Int(color.red)]
        let green = Self.linear[Int(color.green)]
        let blue = Self.linear[Int(color.blue)]
        let long = cbrt(0.4122214708 * red + 0.5363325363 * green + 0.0514459929 * blue)
        let medium = cbrt(0.2119034982 * red + 0.6806995451 * green + 0.1073969566 * blue)
        let short = cbrt(0.0883024619 * red + 0.2817188376 * green + 0.6299787005 * blue)
        lightness = 0.2104542553 * long + 0.7936177850 * medium - 0.0040720468 * short
        a = 1.9779984951 * long - 2.4285922050 * medium + 0.4505937099 * short
        b = 0.0259040371 * long + 0.7827717662 * medium - 0.8086757660 * short
    }

    var chroma: Double { (a * a + b * b).squareRoot() }

    func squaredDistance(to other: OKLab) -> Double {
        let lightnessDifference = lightness - other.lightness
        let aDifference = a - other.a
        let bDifference = b - other.b
        return lightnessDifference * lightnessDifference + aDifference * aDifference + bDifference * bDifference
    }

    func distance(to other: OKLab) -> Double { squaredDistance(to: other).squareRoot() }

    private static let linear: [Double] = (0...255).map {
        let value = Double($0) / 255
        return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }
}
