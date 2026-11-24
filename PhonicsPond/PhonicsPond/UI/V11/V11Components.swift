import SwiftUI
import UIKit

/// Image from the asset kit, or an SF Symbol fallback if the asset is missing.
struct KitIcon: View {
    let name: String
    var fallback: String = "circle"
    var size: CGFloat

    var body: some View {
        if UIImage(named: name) != nil {
            Image(name).resizable().scaledToFit().frame(width: size, height: size)
        } else {
            Image(systemName: fallback).font(.system(size: size * 0.6, weight: .bold)).frame(width: size, height: size)
        }
    }
}

/// Round blue navigation button using a kit icon (Back to books, Home, previous/next).
struct KitRoundButton: View {
    @Environment(\.u) private var u
    let icon: String
    let fallback: String
    let label: String
    var size: CGFloat = 84
    var style: BlueButton.Style = .blue
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            KitIcon(name: icon, fallback: fallback, size: u(size * 0.62))
                .foregroundStyle(style == .blue ? Color.white : Palette.ink)
                .frame(width: u(size), height: u(size))
                .background(
                    RoundedRectangle(cornerRadius: u(size * 0.3), style: .continuous)
                        .fill(style == .blue ? Palette.blue : (style == .cream ? Palette.cream : Palette.lavender))
                        .shadow(color: style == .blue ? Palette.blueDeep : Palette.creamEdge, radius: 0, y: u(5))
                )
        }
        .buttonStyle(PressableStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
        .accessibilityLabel(label)
    }
}

/// A control that plays one recording. With no recording yet it is disabled, dimmed,
/// captioned "coming later" and announced as "Audio coming later" (voice is on hold).
struct AudioButton: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u
    let audioID: String
    let title: String
    var icon = "icon_speaker"
    var fallback = "speaker.wave.2.fill"
    var height: CGFloat = 76
    var style: BlueButton.Style = .blue
    var highlightKey: String?
    var action: (() -> Void)?

    private var available: Bool { app.audio.isAvailable(audioID) }
    private var playing: Bool { app.audio.isHighlighted(highlightKey ?? audioID) }

    var body: some View {
        VStack(spacing: u(2)) {
            Button {
                if let action { action() } else { app.audio.play(audioID, highlight: highlightKey ?? audioID) }
            } label: {
                HStack(spacing: u(10)) {
                    KitIcon(name: icon, fallback: fallback, size: u(height * 0.5))
                    if !title.isEmpty {
                        Text(title).font(Typeface.child(u(height * 0.38))).lineLimit(1).minimumScaleFactor(0.6)
                    }
                }
                .foregroundStyle(style == .blue ? Color.white : Palette.ink)
                .padding(.horizontal, u(height * 0.36))
                .frame(minWidth: u(height * 1.1), minHeight: u(height))
                .background(Capsule().fill(available ? fill : Color(hex: 0xC9CCD6))
                    .shadow(color: available ? shadow : .clear, radius: 0, y: u(5)))
            }
            .buttonStyle(PressableStyle())
            .disabled(!available)
            .playingHighlight(playing, radius: u(height / 2))
            if !available {
                Text("coming later")
                    .font(.system(size: u(15), weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.inkSoft)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(available ? title : "\(title). Audio coming later")
        .accessibilityAddTraits(.isButton)
    }

    private var fill: Color { style == .blue ? Palette.blue : (style == .cream ? Palette.cream : Palette.lavender) }
    private var shadow: Color { style == .blue ? Palette.blueDeep : Palette.creamEdge }
}

/// Butter-yellow target-word chip. Live text; tapping plays the natural word when it is recorded.
struct WordChip: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u
    let word: String
    var size: CGFloat = 64

    private var audioID: String { app.wordID(word) }
    private var available: Bool { app.audio.isAvailable(audioID) }
    private var key: String { "chip.\(word)" }

    var body: some View {
        Button {
            app.playWord(word, highlight: key)
        } label: {
            HStack(spacing: u(10)) {
                Text(word)
                    .font(Typeface.letter(u(size)))
                    .foregroundStyle(Palette.ink)
                KitIcon(name: "icon_speaker", fallback: "speaker.wave.2.fill", size: u(size * 0.5))
                    .opacity(available ? 1 : 0.3)
            }
            .padding(.horizontal, u(size * 0.45))
            .frame(minHeight: u(size * 1.35))
            .background(Capsule().fill(app.audio.isHighlighted(key) ? Palette.butterDeep : Palette.butter)
                .shadow(color: Palette.butterDeep.opacity(0.8), radius: 0, y: u(5)))
        }
        .buttonStyle(PressableStyle())
        .disabled(!available)
        .playingHighlight(app.audio.isHighlighted(key), radius: u(size * 0.7))
        .accessibilityLabel(available ? "word \(word)" : "word \(word). Audio coming later")
    }
}

/// Scene drawn from layered cut-outs on the fixed pond (feet on one ground line).
struct LayeredScene: View {
    let layers: [SceneLayer]
    var groundLine: CGFloat = 0.92
    var sunset = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                if sunset {
                    LinearGradient(colors: [Color(hex: 0xFFB27A, opacity: 0.35), Color(hex: 0xFFE3B0, opacity: 0.05)],
                                   startPoint: .top, endPoint: .bottom)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                ForEach(Array(layers.enumerated()), id: \.offset) { index, layer in
                    let w = geo.size.width * layer.width
                    let h = geo.size.height * 0.95
                    Group {
                        if layer.wobble {
                            WobblingCutout(asset: layer.asset, fallback: nil, label: Self.label(layer.asset),
                                           period: 2.6 + Double(index) * 0.45, phase: Double(index) * 1.1, amplitude: 1.8)
                        } else {
                            Image(layer.asset).resizable().scaledToFit().accessibilityHidden(true)
                        }
                    }
                    .frame(width: w, height: h, alignment: .bottom)
                    .position(x: geo.size.width * layer.x, y: geo.size.height * groundLine - h / 2)
                }
            }
        }
    }

    static func label(_ asset: String) -> String {
        switch asset {
        case "pat_sitting_on_log": return "Pat sitting on a log"
        case "pat_tapping_log": return "Pat tapping the log"
        case "pat_patting": return "Pat patting the puppy"
        case "pat_and_puppy_on_log": return "Pat and the puppy on the log"
        case "puppy_sitting": return "the puppy"
        case "pip_waving_cutout": return "Pip"
        default: return asset.replacingOccurrences(of: "_", with: " ")
        }
    }
}
