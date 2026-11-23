import XCTest
@testable import Kolors

final class PaletteExtractorTests: XCTestCase {
    private func image(_ blocks: [(UIColor, CGRect)], size: CGSize = CGSize(width: 200, height: 200)) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.preferredRange = .standard
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            for (color, rect) in blocks {
                color.setFill()
                context.fill(rect)
            }
        }
    }

    private let full = CGRect(x: 0, y: 0, width: 200, height: 200)

    private func hexes(_ image: UIImage) -> [String] { PaletteExtractor.palette(from: image).map(\.hex) }

    func testAllWhiteReturnsWhiteInsteadOfCrashing() {
        XCTAssertEqual(hexes(image([(.white, full)])), ["#FFFFFF"])
    }

    func testSolidColorsReturnOneExactColor() {
        XCTAssertEqual(hexes(image([(.black, full)])), ["#000000"])
        XCTAssertEqual(hexes(image([(UIColor(red: 1, green: 0, blue: 0, alpha: 1), full)])), ["#FF0000"])
        XCTAssertEqual(hexes(image([(UIColor(white: 128 / 255, alpha: 1), full)])), ["#808080"])
    }

    func testTwoColorImageHasNoInventedColors() {
        let red = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        let blue = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
        let result = hexes(image([(red, full), (blue, CGRect(x: 100, y: 0, width: 100, height: 200))]))
        XCTAssertEqual(Set(result), ["#FF0000", "#0000FF"])
        XCTAssertEqual(result.count, 2)
    }

    func testBlackOnWhiteReturnsBlack() {
        XCTAssertEqual(hexes(image([(.white, full), (.black, CGRect(x: 0, y: 0, width: 50, height: 50))])), ["#000000"])
    }

    func testSingleNonWhitePixel() {
        XCTAssertEqual(hexes(image([(.white, full), (.black, CGRect(x: 0, y: 0, width: 1, height: 1))])), ["#000000"])
    }

    func testTransparentAndEmptyImages() {
        XCTAssertEqual(hexes(image([])), ["#FFFFFF"])
        XCTAssertEqual(hexes(UIImage()), [])
    }

    func testImageWithoutCGImage() {
        let ciImage = CIImage(color: CIColor(red: 0, green: 1, blue: 0)).cropped(to: CGRect(x: 0, y: 0, width: 40, height: 40))
        XCTAssertFalse(PaletteExtractor.palette(from: UIImage(ciImage: ciImage)).isEmpty)
    }

    func testColorfulImageReturnsFiveDistinctColors() {
        let blocks = (0..<40).map { index in
            (UIColor(hue: CGFloat(index) / 40, saturation: 0.9, brightness: 0.9, alpha: 1),
             CGRect(x: index * 5, y: 0, width: 5, height: 200))
        }
        let result = hexes(image(blocks))
        XCTAssertEqual(result.count, 5)
        XCTAssertEqual(Set(result).count, 5)
    }

    /// A ramp of reds covers 70% of the picture. Its steep steps are the kind of pixels skipped as edge blends.
    func testBusyTextureStillCountsAsCoverage() {
        var blocks: [(UIColor, CGRect)] = [(color(0x2040D0), full)]
        for x in 0..<140 {
            let brightness = [0.75, 0.85, 0.95, 0.85][x % 4]
            blocks.append((UIColor(hue: 0, saturation: 0.8, brightness: brightness, alpha: 1),
                           CGRect(x: x, y: 0, width: 1, height: 200)))
        }
        let result = PaletteExtractor.palette(from: image(blocks))
        XCTAssertGreaterThan(result[0].red, result[0].blue, "\(result.map(\.hex))")
    }

    private func color(_ hex: UInt32) -> UIColor {
        UIColor(
            red: CGFloat(hex >> 16) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1
        )
    }

    private func scene(sky: UInt32, sun: UInt32, hills: [UInt32], size: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.preferredRange = .standard
        return UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format).image { context in
            color(sky).setFill()
            context.fill(CGRect(x: 0, y: 0, width: size, height: size))
            color(sun).setFill()
            context.cgContext.fillEllipse(in: CGRect(x: size * 0.2, y: size * 0.15, width: size * 0.2, height: size * 0.2))
            for (index, hill) in hills.enumerated() {
                color(hill).setFill()
                let top = size * (0.5 + 0.16 * CGFloat(index))
                context.cgContext.fillEllipse(in: CGRect(x: -size * 0.5, y: top, width: size * 2, height: size * 2))
            }
        }
    }

    /// Includes sizes that have to be scaled down, which blends colors along the edges.
    func testFlatArtReturnsExactlyItsOwnColors() {
        let scenes: [(sky: UInt32, sun: UInt32, hills: [UInt32])] = [
            (0xBFE3E0, 0xFFF3C9, [0x5FB0B7, 0x2B7A8C, 0x14405A]),
            (0xF3E3C3, 0xE9A23B, [0x9DB36B, 0x4F7F4A, 0x1F4D3A]),
            (0xF6A68B, 0xFFE2A0, [0xD95D77, 0x7C3F7E, 0x2E2A5E])
        ]
        for scene in scenes {
            let expected = Set(([scene.sky, scene.sun] + scene.hills).map { String(format: "#%06X", $0) })
            for size in [CGFloat(200), 1000, 1333] {
                let result = hexes(self.scene(sky: scene.sky, sun: scene.sun, hills: scene.hills, size: size))
                XCTAssertEqual(Set(result), expected, "\(size)")
            }
        }
    }

    func testDistinctDarkColorsStaySeparate() {
        let result = hexes(image([
            (color(0x000000), full),
            (color(0x14213D), CGRect(x: 0, y: 0, width: 80, height: 200)),
            (color(0x3D1414), CGRect(x: 80, y: 0, width: 50, height: 200))
        ]))
        XCTAssertEqual(Set(result), ["#000000", "#14213D", "#3D1414"])
    }

    /// Muted blues and greens of every brightness fill the picture except for an orange patch covering 1% of it.
    func testSmallVividAccentBeatsMoreBackgroundShades() {
        var blocks = (0..<400).map { index in
            (UIColor(hue: 0.28 + 0.017 * CGFloat(index % 20), saturation: 0.35,
                     brightness: 0.1 + 0.045 * CGFloat(index / 20), alpha: 1),
             CGRect(x: index % 20 * 10, y: index / 20 * 10, width: 10, height: 10))
        }
        blocks.append((color(0xF29B00), CGRect(x: 90, y: 90, width: 20, height: 20)))
        let result = hexes(image(blocks))
        XCTAssertEqual(result.count, 5)
        XCTAssertTrue(result.contains("#F29B00"), "\(result)")
    }

    func testColorsAreInTheImageAndRepeatable() {
        var seed: UInt64 = 1
        func next() -> CGFloat {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return CGFloat(seed >> 56)
        }
        var used = Set<String>()
        let blocks: [(UIColor, CGRect)] = (0..<1600).map { index in
            let (red, green, blue) = (next(), next(), next())
            used.insert(String(format: "#%02X%02X%02X", Int(red), Int(green), Int(blue)))
            return (UIColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1),
                    CGRect(x: index % 40 * 5, y: index / 40 * 5, width: 5, height: 5))
        }
        let picture = image(blocks)
        let result = hexes(picture)
        XCTAssertEqual(result.count, 5)
        XCTAssertTrue(used.isSuperset(of: result), "\(result)")
        XCTAssertEqual(hexes(picture), result)
    }

    func testMostCommonColorComesFirst() {
        let result = hexes(image([(color(0x14405A), full), (color(0xFF0000), CGRect(x: 0, y: 0, width: 200, height: 60))]))
        XCTAssertEqual(result, ["#14405A", "#FF0000"])
    }

    func testResizeLimitsLongestSideAndNeverEnlarges() {
        let large = image([(.red, CGRect(x: 0, y: 0, width: 3000, height: 1500))], size: CGSize(width: 3000, height: 1500))
        XCTAssertEqual(ImageProcessing.resized(large, maxPixels: 1200)?.size, CGSize(width: 1200, height: 600))
        XCTAssertEqual(ImageProcessing.resized(image([(.red, full)]), maxPixels: 1200)?.size, full.size)
    }

    func testHex() {
        XCTAssertEqual(RGBColor(red: 0, green: 10, blue: 255).hex, "#000AFF")
    }

    func testBarTextIsAlwaysReadable() {
        for red in stride(from: 0, through: 255, by: 15) {
            for green in stride(from: 0, through: 255, by: 15) {
                for blue in stride(from: 0, through: 255, by: 15) {
                    let color = RGBColor(red: UInt8(red), green: UInt8(green), blue: UInt8(blue))
                    let contrast = color.prefersWhiteText ? 1.05 / (color.luminance + 0.05) : (color.luminance + 0.05) / 0.05
                    XCTAssertGreaterThanOrEqual(contrast, 4.5, color.hex)
                }
            }
        }
    }

    func testShareImageFitsPhotoAndColors() {
        let photo = image([(.red, full)])
        XCTAssertEqual(PaletteShareImage.render(photo: photo, colors: SampleArtwork.palette).size, CGSize(width: 1080, height: 1520))
        XCTAssertEqual(PaletteShareImage.render(photo: nil, colors: SampleArtwork.palette).size, CGSize(width: 1080, height: 800))
    }

    func testFormats() {
        let color = RGBColor(red: 1, green: 20, blue: 255)
        XCTAssertEqual(ColorFormat.hex.text(for: color), "#0114FF")
        XCTAssertEqual(ColorFormat.rgb.text(for: color), "1, 20, 255")
    }
}
