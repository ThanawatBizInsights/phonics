import CoreText
import SwiftUI

/// Colours sampled from the approved Phonics Pond references.
enum Palette {
    static let ink = Color(hex: 0x1C1F45)
    static let inkSoft = Color(hex: 0x4A4F7A)
    static let cream = Color(hex: 0xFBF6EA)
    static let creamEdge = Color(hex: 0xE6DCC5)
    static let blue = Color(hex: 0x2F8BEA)
    static let blueDeep = Color(hex: 0x1D6CC9)
    static let lavender = Color(hex: 0xDDD4F8)
    static let lavenderDeep = Color(hex: 0xB6A6EE)
    static let butter = Color(hex: 0xFFE68A)
    static let butterDeep = Color(hex: 0xF2C64A)
    static let periwinkle = Color(hex: 0x8C86E3)
    static let peach = Color(hex: 0xFFCDB0)
    static let skyTop = Color(hex: 0x9FD3F4)
    static let skyBottom = Color(hex: 0xEAF6FD)
    static let hillFar = Color(hex: 0xA6D17F)
    static let hillNear = Color(hex: 0x8DC366)
    static let grassTop = Color(hex: 0x9FD465)
    static let grassBottom = Color(hex: 0x6CAF45)
    static let pond = Color(hex: 0x86CBEC)
    static let pondDeep = Color(hex: 0x4E9FD0)
    static let lily = Color(hex: 0x7BBF55)
    static let sand = Color(hex: 0xEBD5A8)
    static let sandDeep = Color(hex: 0xD2B07A)
    static let trayRim = Color(hex: 0xF3EBDD)
    static let trayBase = Color(hex: 0xA9D3EE)
    static let success = Color(hex: 0x6CC08B)
    static let pending = Color(hex: 0xE4572E)
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

/// Andika (SIL, OFL) has the single-storey a and g that early readers are taught.
enum Typeface {
    static func letter(_ size: CGFloat) -> Font { .custom("Andika-Bold", fixedSize: size) }
    static func child(_ size: CGFloat) -> Font { .custom("Andika-Bold", fixedSize: size) }
    static func childRegular(_ size: CGFloat) -> Font { .custom("Andika-Regular", fixedSize: size) }

    /// Registers the bundled fonts at launch, so no Info.plist entry is needed.
    static func registerBundledFonts(bundle: Bundle = .main) {
        for name in ["Andika-Regular", "Andika-Bold"] {
            guard let url = bundle.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

/// The layout is drawn on an 11-inch iPad landscape canvas and scaled to the screen.
enum CanvasSize {
    static let width: CGFloat = 1194
    static let height: CGFloat = 834
}

/// Converts canvas points to screen points: `u(120)`.
struct Unit {
    var k: CGFloat = 1
    func callAsFunction(_ value: CGFloat) -> CGFloat { value * k }
}

private struct UnitKey: EnvironmentKey {
    static let defaultValue = Unit()
}

extension EnvironmentValues {
    var u: Unit {
        get { self[UnitKey.self] }
        set { self[UnitKey.self] = newValue }
    }
}
