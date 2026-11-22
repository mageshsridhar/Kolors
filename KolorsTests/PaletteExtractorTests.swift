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
