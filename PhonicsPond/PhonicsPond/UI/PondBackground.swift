import SwiftUI
import UIKit

/// The sunny pond behind every screen.
/// Uses the clean "pond_background" artwork when it is added to the asset catalog;
/// until then a drawn placeholder keeps the same composition (sky, sun, hills, pond, grass).
struct PondBackground: View {
    var body: some View {
        if UIImage(named: ArtworkNames.pondBackground) != nil {
            Image(ArtworkNames.pondBackground)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .accessibilityHidden(true)
        } else {
            DrawnPond()
                .ignoresSafeArea()
                .accessibilityHidden(true)
        }
    }
}

private struct DrawnPond: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                LinearGradient(colors: [Palette.skyTop, Palette.skyBottom], startPoint: .top, endPoint: .center)

                Circle()
                    .fill(RadialGradient(colors: [Color.white, Color(hex: 0xFFF3B8), Color(hex: 0xFFF3B8, opacity: 0)],
                                         center: .center, startRadius: 0, endRadius: w * 0.12))
                    .frame(width: w * 0.24, height: w * 0.24)
                    .position(x: w * 0.84, y: h * 0.09)

                Ellipse().fill(Palette.hillFar)
                    .frame(width: w * 1.2, height: h * 0.42)
                    .position(x: w * 0.75, y: h * 0.40)
                Ellipse().fill(Palette.hillNear)
                    .frame(width: w * 0.95, height: h * 0.40)
                    .position(x: w * 0.12, y: h * 0.42)

                Rectangle()
                    .fill(LinearGradient(colors: [Palette.grassTop, Palette.grassBottom], startPoint: .top, endPoint: .bottom))
                    .frame(width: w, height: h * 0.66)
                    .position(x: w / 2, y: h * 0.67)

                Ellipse()
                    .fill(LinearGradient(colors: [Palette.pond, Palette.pondDeep], startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.8, height: h * 0.25)
                    .position(x: w * 0.66, y: h * 0.42)
                ForEach(Self.lilyPads, id: \.x) { pad in
                    Ellipse().fill(Palette.lily)
                        .frame(width: w * pad.size, height: w * pad.size * 0.32)
                        .position(x: w * pad.x, y: h * pad.y)
                }
                ForEach(Self.flowers, id: \.x) { flower in
                    Circle().fill(flower.color)
                        .frame(width: w * 0.014, height: w * 0.014)
                        .position(x: w * flower.x, y: h * flower.y)
                }
            }
        }
    }

    private struct Pad { let x: CGFloat; let y: CGFloat; let size: CGFloat }
    private struct Flower { let x: CGFloat; let y: CGFloat; let color: Color }

    private static let lilyPads = [Pad(x: 0.48, y: 0.40, size: 0.06), Pad(x: 0.72, y: 0.45, size: 0.07),
                                   Pad(x: 0.88, y: 0.38, size: 0.05), Pad(x: 0.60, y: 0.48, size: 0.045)]
    private static let flowers = [Flower(x: 0.05, y: 0.62, color: .white), Flower(x: 0.13, y: 0.90, color: Color(hex: 0xC9A6F2)),
                                  Flower(x: 0.93, y: 0.66, color: .white), Flower(x: 0.97, y: 0.86, color: Color(hex: 0xC9A6F2)),
                                  Flower(x: 0.36, y: 0.58, color: .white), Flower(x: 0.79, y: 0.60, color: .white)]
}

/// Asset catalog names for artwork. Anything listed in `required` but not yet in
/// the catalog shows a marked placeholder (see docs/design/level-1-asset-list.md).
enum ArtworkNames {
    static let pondBackground = "pond_background"
    static let patWavingCutout = "pat_waving_cutout"
    static let patWaving = "pat_waving"
    static let patSittingLog = "pat_sitting_log"

    /// Story pictures that are transparent cut-outs of characters (drawn as wobbling layers).
    static let characterCutouts: Set<String> = ["pat_waving_cutout", "pat_patting", "pat_tapping", "puppy_sitting", "pip_waving_cutout",
                                                "pat_sitting_on_log", "pat_tapping_log", "pat_and_puppy_on_log", "duck_sitting"]

    static let requiredAssets: [String] = [
        pondBackground, patWavingCutout, patWaving, patSittingLog, "pat_patting", "pat_tapping",
        "object_sock", "object_pen", "object_pot",
        "mouth_s", "action_s", "mouth_a", "action_a",
        "mouth_t", "action_t", "mouth_p", "action_p",
        "sticker_pat", "sticker_lily", "sticker_star", "puppy_sitting",
        "pat_sitting_on_log", "pat_tapping_log", "pat_and_puppy_on_log", "pip_waving_cutout",
        "trophy_page", "trophy_level", "home_storybook", "home_phonics", "home_stickers", "home_grownups",
        "book_cover_01", "book_cover_02", "book_cover_03", "book_cover_04", "book_cover_05", "book_cover_06",
        "book_cover_07", "book_cover_08", "book_cover_09", "book_cover_10", "book_cover_11", "book_cover_12"
    ]

    static var missing: [String] { requiredAssets.filter { UIImage(named: $0) == nil } }
}
