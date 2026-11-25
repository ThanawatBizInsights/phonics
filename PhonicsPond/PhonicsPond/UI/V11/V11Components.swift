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

// MARK: - Shared row metrics

/// One set of sizes for every control that shares a row on the Storybook, Phonics and Stickers screens,
/// so paired controls have the same height, padding and icon size, and line up on one centre.
enum ControlMetrics {
    /// Buttons, chips and speakers that share a row.
    static let row: CGFloat = 76
    /// Larger paired actions (trophy overlays, the Phonics "Hear sound").
    static let large: CGFloat = 84
    /// Label size relative to the control height.
    static let textRatio: CGFloat = 0.35
    static let iconRatio: CGFloat = 0.42
    static let paddingRatio: CGFloat = 0.32
    static let spacing: CGFloat = 10

    /// Control labels follow the system text size (capped), on top of the canvas scale.
    static func textScale(_ size: DynamicTypeSize) -> CGFloat {
        switch size {
        case .xSmall, .small, .medium, .large: return 1
        case .xLarge: return 1.08
        case .xxLarge: return 1.16
        case .xxxLarge: return 1.24
        default: return 1.32    // accessibility sizes (capped at about .accessibility1)
        }
    }
}

private struct StretchToRowKey: EnvironmentKey { static let defaultValue = false }

extension EnvironmentValues {
    /// Set by `alignedRow()`: controls grow to the tallest control in their row.
    var stretchToRow: Bool {
        get { self[StretchToRowKey.self] }
        set { self[StretchToRowKey.self] = newValue }
    }
}

extension View {
    /// A row of controls that share one height and one vertical centre. If larger text wraps
    /// one label onto two lines, its neighbours grow with it instead of sitting out of line.
    func alignedRow() -> some View {
        environment(\.stretchToRow, true).fixedSize(horizontal: false, vertical: true)
    }
}

extension Typeface {
    /// Label font for buttons and chips: canvas-scaled and Dynamic Type-scaled (capped).
    static func control(_ size: CGFloat, _ dynamicType: DynamicTypeSize) -> Font {
        .custom("Andika-Bold", fixedSize: size * ControlMetrics.textScale(dynamicType))
    }
}

/// The inside of a capsule control: icon and label on one vertical centre. The label wraps to two
/// lines rather than being cut off or shrunk; the capsule grows, and rows keep a shared centre.
struct PillLabel: View {
    @Environment(\.u) private var u
    @Environment(\.stretchToRow) private var stretch
    @Environment(\.dynamicTypeSize) private var dynamicType
    let title: String
    var icon: String? = nil           // kit asset name
    var symbol: String? = nil         // SF Symbol (or the kit icon's fallback)
    var trailingSymbol: String? = nil
    var height: CGFloat = ControlMetrics.row
    var width: CGFloat? = nil
    var style: BlueButton.Style = .blue
    var available = true
    /// Shown inside the capsule when the recording is still on hold (instead of a caption below it).
    var pending = false

    var body: some View {
        let iconSize = u(height * ControlMetrics.iconRatio)
        HStack(spacing: u(ControlMetrics.spacing)) {
            if let icon {
                KitIcon(name: icon, fallback: symbol ?? "circle", size: iconSize)
            } else if let symbol {
                Image(systemName: symbol).font(.system(size: iconSize * 0.8, weight: .bold)).frame(width: iconSize, height: iconSize)
            }
            if !title.isEmpty {
                Text(title)
                    .font(Typeface.control(u(height * ControlMetrics.textRatio), dynamicType))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let trailingSymbol {
                Image(systemName: trailingSymbol).font(.system(size: iconSize * 0.8, weight: .bold)).frame(width: iconSize, height: iconSize)
            }
            if pending {
                Image(systemName: "clock").font(.system(size: iconSize * 0.6, weight: .semibold))
                    .foregroundStyle(Palette.inkSoft)
                    .accessibilityHidden(true)
            }
        }
        .foregroundStyle(!available ? Palette.inkSoft : (style == .blue ? Color.white : Palette.ink))
        .padding(.horizontal, u(height * ControlMetrics.paddingRatio))
        .padding(.vertical, u(6))
        .frame(minWidth: width.map { u($0) } ?? u(height), maxWidth: width.map { u($0) },
               minHeight: u(height), maxHeight: stretch ? CGFloat.infinity : nil, alignment: .center)
        .background(Capsule().fill(available ? style.fill : Color(hex: 0xD9DBE3))
            .shadow(color: available ? style.shadow : .clear, radius: 0, y: u(5)))
    }
}

extension BlueButton.Style {
    var fill: Color {
        switch self {
        case .blue: return Palette.blue
        case .lavender: return Palette.lavender
        case .cream: return Palette.cream
        }
    }
    var shadow: Color {
        switch self {
        case .blue: return Palette.blueDeep
        case .lavender: return Palette.lavenderDeep
        case .cream: return Palette.creamEdge
        }
    }
}

/// A capsule action button (Next page, Finish story, Random word, Bookshelf ...).
struct PillButton: View {
    let title: String
    var icon: String? = nil
    var symbol: String? = nil
    var trailingSymbol: String? = nil
    var height: CGFloat = ControlMetrics.row
    var width: CGFloat? = nil
    var style: BlueButton.Style = .blue
    var enabled = true
    /// Spoken label when it should differ from the visible one.
    var accessibilityText: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            PillLabel(title: title, icon: icon, symbol: symbol, trailingSymbol: trailingSymbol,
                      height: height, width: width, style: style)
        }
        .buttonStyle(PressableStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
        .accessibilityLabel(accessibilityText ?? title)
    }
}

/// A control that plays one recording. With no recording yet it is disabled, greyed, shows a small
/// clock inside the capsule and is announced as "Audio coming later" (voice is on hold).
/// It never adds a caption below itself, so it keeps the same height as its neighbours.
struct AudioButton: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u
    let audioID: String
    let title: String
    var icon = "icon_speaker"
    var fallback = "speaker.wave.2.fill"
    var height: CGFloat = ControlMetrics.row
    var width: CGFloat? = nil
    var style: BlueButton.Style = .blue
    var highlightKey: String?
    var action: (() -> Void)?

    private var available: Bool { app.audio.isAvailable(audioID) }
    private var playing: Bool { app.audio.isHighlighted(highlightKey ?? audioID) }

    var body: some View {
        Button {
            if let action { action() } else { app.audio.play(audioID, highlight: highlightKey ?? audioID) }
        } label: {
            PillLabel(title: title, icon: icon, symbol: fallback, height: height, width: width,
                      style: style, available: available, pending: !available)
        }
        .buttonStyle(PressableStyle())
        .disabled(!available)
        .playingHighlight(playing, radius: u(height / 2))
        .accessibilityLabel(available ? title : "\(title). Audio coming later")
    }
}

/// A fixed-size round speaker for rows where a full text label would crowd (example words).
/// The accessible label names what it plays, e.g. "Hear tap".
struct SpeakerButton: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u
    let audioID: String
    let label: String
    var size: CGFloat = ControlMetrics.row
    var highlightKey: String?

    private var available: Bool { app.audio.isAvailable(audioID) }
    private var key: String { highlightKey ?? audioID }

    var body: some View {
        Button {
            app.audio.play(audioID, highlight: key)
        } label: {
            KitIcon(name: "icon_speaker", fallback: "speaker.wave.2.fill", size: u(size * 0.5))
                .foregroundStyle(available ? Color.white : Palette.inkSoft)
                .frame(width: u(size), height: u(size))
                .background(RoundedRectangle(cornerRadius: u(size * 0.32), style: .continuous)
                    .fill(available ? Palette.blue : Color(hex: 0xD9DBE3))
                    .shadow(color: available ? Palette.blueDeep : .clear, radius: 0, y: u(5)))
        }
        .buttonStyle(PressableStyle())
        .disabled(!available)
        .playingHighlight(app.audio.isHighlighted(key), radius: u(size * 0.32))
        .accessibilityLabel(available ? label : "\(label). Audio coming later")
    }
}

/// Butter-yellow target-word chip, the same height as the buttons beside it.
/// Live text; tapping plays the natural word when it is recorded.
struct WordChip: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u
    @Environment(\.dynamicTypeSize) private var dynamicType
    @Environment(\.stretchToRow) private var stretch
    let word: String
    var size: CGFloat = 40
    var height: CGFloat = ControlMetrics.row

    private var audioID: String { app.wordID(word) }
    private var available: Bool { app.audio.isAvailable(audioID) }
    private var key: String { "chip.\(word)" }

    var body: some View {
        Button {
            app.playWord(word, highlight: key)
        } label: {
            HStack(spacing: u(ControlMetrics.spacing)) {
                Text(word)
                    .font(.custom("Andika-Bold", fixedSize: u(size) * ControlMetrics.textScale(dynamicType)))
                    .foregroundStyle(Palette.ink)
                    .fixedSize()
                KitIcon(name: "icon_speaker", fallback: "speaker.wave.2.fill", size: u(height * 0.36))
                    .opacity(available ? 1 : 0.3)
            }
            .padding(.horizontal, u(height * 0.24))
            .frame(minHeight: u(height), maxHeight: stretch ? CGFloat.infinity : nil)
            .background(Capsule().fill(app.audio.isHighlighted(key) ? Palette.butterDeep : Palette.butter)
                .shadow(color: Palette.butterDeep.opacity(0.8), radius: 0, y: u(5)))
        }
        .buttonStyle(PressableStyle())
        .disabled(!available)
        .playingHighlight(app.audio.isHighlighted(key), radius: u(height / 2))
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
