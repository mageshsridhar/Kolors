import SwiftUI

/// An 8-bit sRGB color. The hex string is derived, never stored.
struct RGBColor: Hashable {
    let red: UInt8
    let green: UInt8
    let blue: UInt8

    var hex: String {
        String(format: "#%02X%02X%02X", Int(red), Int(green), Int(blue))
    }

    var rgbText: String { "\(red), \(green), \(blue)" }

    /// WCAG relative luminance.
    var luminance: Double {
        func linear(_ value: UInt8) -> Double {
            let channel = Double(value) / 255
            return channel <= 0.03928 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    /// Whether white text is more readable than black on this color.
    var prefersWhiteText: Bool { 1.05 / (luminance + 0.05) >= (luminance + 0.05) / 0.05 }

    var textColor: Color { prefersWhiteText ? .white : .black }

    var color: Color {
        Color(.sRGB, red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255)
    }
}
