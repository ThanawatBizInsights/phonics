import SwiftUI
import UIKit

// MARK: - Panels and labels

/// The cream rounded panels from the references.
struct CreamPanel: ViewModifier {
    @Environment(\.u) private var u
    var radius: CGFloat = 40
    var fill: Color = Palette.cream

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: u(radius), style: .continuous)
                    .fill(fill)
                    .shadow(color: .black.opacity(0.12), radius: u(12), y: u(6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: u(radius), style: .continuous)
                    .stroke(Palette.creamEdge, lineWidth: u(3))
            )
    }
}

extension View {
    func creamPanel(radius: CGFloat = 40, fill: Color = Palette.cream) -> some View {
        modifier(CreamPanel(radius: radius, fill: fill))
    }
}

/// Butter-yellow or lavender capsule ("level 1 · page 1", "ears warm-up").
struct Pill: View {
    @Environment(\.u) private var u
    let text: String
    var color: Color = Palette.butter
    var size: CGFloat = 30

    var body: some View {
        Text(text)
            .font(Typeface.child(u(size)))
            .foregroundStyle(Palette.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.horizontal, u(size * 0.95))
            .padding(.vertical, u(size * 0.32))
            .background(Capsule().fill(color))
            .overlay(Capsule().stroke(Color.white.opacity(0.75), lineWidth: u(3)))
    }
}

/// One-line instruction shown on every screen (also spoken).
struct InstructionBubble: View {
    @Environment(\.u) private var u
    let text: String
    var size: CGFloat = 40

    var body: some View {
        Text(text)
            .font(Typeface.child(u(size)))
            .foregroundStyle(Palette.ink)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, u(36))
            .padding(.vertical, u(18))
            .creamPanel(radius: 30)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Buttons

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Slow breathing scale used to draw attention, without flashing. Off with Reduce Motion
/// (a steady butter ring is shown instead).
struct Pulse: ViewModifier {
    let active: Bool
    var radius: CGFloat = 24
    @State private var on = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(active && on && !reduceMotion ? 1.07 : 1)
            .overlay {
                if active {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .stroke(Palette.butterDeep, lineWidth: 5)
                        .padding(-7)
                }
            }
            .animation(active && !reduceMotion ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true) : .default, value: on)
            .onAppear { on = active }
            .onChange(of: active) { _, newValue in on = newValue }
    }
}

extension View {
    func pulse(_ active: Bool, radius: CGFloat = 24) -> some View { modifier(Pulse(active: active, radius: radius)) }
}

/// Square chrome button (home, replay). 76 pt on the canvas.
struct SquareIconButton: View {
    @Environment(\.u) private var u
    enum Style { case blue, cream }
    let systemName: String
    let label: String
    var style: Style = .blue
    var pulsing = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: u(34), weight: .bold))
                .foregroundStyle(style == .blue ? Color.white : Palette.ink)
                .frame(width: u(80), height: u(80))
                .background(
                    RoundedRectangle(cornerRadius: u(22), style: .continuous)
                        .fill(style == .blue ? Palette.blue : Palette.cream)
                        .shadow(color: style == .blue ? Palette.blueDeep : Palette.creamEdge, radius: 0, y: u(5))
                )
        }
        .buttonStyle(PressableStyle())
        .pulse(pulsing, radius: u(22))
        .accessibilityLabel(label)
    }
}

/// Round help button ("?").
struct HelpButton: View {
    @Environment(\.u) private var u
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("?")
                .font(Typeface.child(u(40)))
                .foregroundStyle(Palette.ink)
                .frame(width: u(84), height: u(84))
                .background(Circle().fill(Palette.lavender).shadow(color: Palette.lavenderDeep, radius: 0, y: u(4)))
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("help")
    }
}

/// Blue capsule with icon and label ("hear", "hear the word", "next →").
struct BlueButton: View {
    @Environment(\.u) private var u
    let title: String
    var systemImage: String? = nil
    var trailingImage: String? = nil
    var height: CGFloat = 92
    var style: Style = .blue
    var enabled = true
    let action: () -> Void

    enum Style { case blue, lavender, cream }

    var body: some View {
        Button(action: action) {
            HStack(spacing: u(14)) {
                if let systemImage { Image(systemName: systemImage).font(.system(size: u(height * 0.38), weight: .bold)) }
                if !title.isEmpty { Text(title).font(Typeface.child(u(height * 0.44))).lineLimit(1).minimumScaleFactor(0.6) }
                if let trailingImage { Image(systemName: trailingImage).font(.system(size: u(height * 0.38), weight: .bold)) }
            }
            .foregroundStyle(style == .blue ? Color.white : Palette.ink)
            .padding(.horizontal, u(height * 0.42))
            .frame(minWidth: u(height * 1.4), minHeight: u(height))
            .background(
                Capsule()
                    .fill(fill)
                    .shadow(color: shadow, radius: 0, y: u(6))
            )
        }
        .buttonStyle(PressableStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.35)
        .accessibilityLabel(title.isEmpty ? (systemImage ?? trailingImage ?? "button") : title)
    }

    private var fill: Color {
        switch style {
        case .blue: return Palette.blue
        case .lavender: return Palette.lavender
        case .cream: return Palette.cream
        }
    }

    private var shadow: Color {
        switch style {
        case .blue: return Palette.blueDeep
        case .lavender: return Palette.lavenderDeep
        case .cream: return Palette.creamEdge
        }
    }
}

/// The "next →" arrow button used at the end of each step.
struct NextButton: View {
    var title = "next"
    var enabled = true
    let action: () -> Void

    var body: some View {
        BlueButton(title: title, trailingImage: "arrow.right", height: 88, enabled: enabled, action: action)
            .accessibilityLabel(title)
    }
}

// MARK: - Letters

/// A lowercase teaching tile. Letters stay the dominant element.
struct LetterTile: View {
    @Environment(\.u) private var u
    let text: String
    var size: CGFloat = 150
    var fill: Color = Palette.cream
    var lit = false
    var glow = false
    var dashed = false

    var body: some View {
        Text(text)
            .font(Typeface.letter(u(size * 0.66)))
            .foregroundStyle(Palette.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(width: u(size), height: u(size * 1.06))
            .background(
                RoundedRectangle(cornerRadius: u(size * 0.18), style: .continuous)
                    .fill(dashed ? Color.white.opacity(0.35) : (lit ? Palette.butter : fill))
                    .shadow(color: dashed ? .clear : Palette.creamEdge.opacity(0.9), radius: 0, y: u(6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: u(size * 0.18), style: .continuous)
                    .strokeBorder(dashed ? Palette.lavenderDeep : Color.white.opacity(0.7),
                                  style: StrokeStyle(lineWidth: u(dashed ? 4 : 3), dash: dashed ? [u(12), u(8)] : []))
            )
            .overlay(
                RoundedRectangle(cornerRadius: u(size * 0.18), style: .continuous)
                    .stroke(Palette.lavenderDeep, lineWidth: glow ? u(9) : 0)
                    .padding(-u(4))
            )
    }
}

// MARK: - Artwork

/// An illustration from the asset catalog, or a clearly marked placeholder naming the asset still needed.
struct Illustration: View {
    @Environment(\.u) private var u
    let assetName: String?
    let description: String
    var corner: CGFloat = 28
    var fill: Bool = true

    var body: some View {
        Group {
            if let assetName, UIImage(named: assetName) != nil {
                Image(assetName)
                    .resizable()
                    .aspectRatio(contentMode: fill ? .fill : .fit)
            } else {
                PlaceholderArt(assetName: assetName ?? "(none)", description: description)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: u(corner), style: .continuous))
        .accessibilityElement()
        .accessibilityLabel(description)
        .accessibilityAddTraits(.isImage)
    }
}

/// Visible stand-in for artwork that hasn't been supplied yet.
struct PlaceholderArt: View {
    @Environment(\.u) private var u
    let assetName: String
    let description: String

    var body: some View {
        ZStack {
            Palette.lavender.opacity(0.55)
            VStack(spacing: u(8)) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: u(40)))
                    .foregroundStyle(Palette.inkSoft)
                Text("art needed")
                    .font(.system(size: u(18), weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.pending)
                Text(assetName)
                    .font(.system(size: u(15), weight: .medium, design: .monospaced))
                    .foregroundStyle(Palette.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(description)
                    .font(.system(size: u(15), weight: .regular, design: .rounded))
                    .foregroundStyle(Palette.inkSoft)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
            }
            .padding(u(12))
        }
        .overlay(
            RoundedRectangle(cornerRadius: u(24), style: .continuous)
                .strokeBorder(Palette.lavenderDeep, style: StrokeStyle(lineWidth: u(3), dash: [u(10), u(7)]))
        )
    }
}

/// Pat, the periwinkle plush penguin with the peach scarf.
/// Uses a transparent cut-out when supplied; until then, the approved artwork crop with a soft oval edge.
struct Mascot: View {
    enum Pose { case waving, sitting }
    var pose: Pose = .waving

    var body: some View {
        Group {
            if pose == .waving, UIImage(named: ArtworkNames.patWavingCutout) != nil {
                Image(ArtworkNames.patWavingCutout).resizable().scaledToFit()
            } else {
                Image(pose == .waving ? ArtworkNames.patWaving : ArtworkNames.patSittingLog)
                    .resizable()
                    .scaledToFit()
                    .mask(
                        EllipticalGradient(stops: [.init(color: .black, location: 0),
                                                   .init(color: .black, location: 0.62),
                                                   .init(color: .clear, location: 0.98)],
                                           center: .center)
                    )
            }
        }
        .accessibilityLabel("Pat the penguin")
        .accessibilityAddTraits(.isImage)
    }
}

// MARK: - Grown-up gate

enum GrownUpGate {
    /// Seconds the lock must be held. A quick tap does nothing.
    static let holdSeconds: Double = 3
}

/// Lock button that opens grown-up areas after a three-second hold, with a filling ring.
struct HoldToOpenButton: View {
    @Environment(\.u) private var u
    var size: CGFloat = 80
    var label = "Grown-ups"
    let action: () -> Void
    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: u(size * 0.28), style: .continuous)
                .fill(Palette.cream)
                .shadow(color: Palette.creamEdge, radius: 0, y: u(5))
            Image(systemName: "lock.fill")
                .font(.system(size: u(size * 0.4), weight: .bold))
                .foregroundStyle(Palette.ink)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Palette.blue, style: StrokeStyle(lineWidth: u(6), lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(u(6))
        }
        .frame(width: u(size), height: u(size))
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: GrownUpGate.holdSeconds, maximumDistance: 40, perform: {
            progress = 0
            action()
        }, onPressingChanged: { pressing in
            if pressing {
                withAnimation(.linear(duration: GrownUpGate.holdSeconds)) { progress = 1 }
            } else {
                withAnimation(.easeOut(duration: 0.2)) { progress = 0 }
            }
        })
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityHint("Touch and hold for three seconds to open.")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Development

/// Debug-only banner listing recordings that are still missing. Never shown in release builds.
struct PendingAudioBanner: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u
    @State private var expanded = false

    var body: some View {
        #if DEBUG
        if let last = app.audio.lastMissing {
            Button {
                expanded.toggle()
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DEV · audio pending: \(last).wav")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    if expanded {
                        Text(app.audio.missingIDs.sorted().joined(separator: "\n"))
                            .font(.system(size: 11, design: .monospaced))
                    }
                    Text("\(app.audio.missingIDs.count) missing so far · tap for list")
                        .font(.system(size: 11, design: .monospaced))
                        .opacity(0.85)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 10).fill(Palette.pending.opacity(0.92)))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("pendingAudioBanner")
        }
        #else
        EmptyView()
        #endif
    }
}
