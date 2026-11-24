import SwiftUI
import UIKit

// MARK: - Motion policy

private struct ReducedStoryMotionKey: EnvironmentKey {
    static let defaultValue = false
}

private struct PageCastKey: EnvironmentKey {
    static let defaultValue: [String] = ["pat"]
}

extension EnvironmentValues {
    /// True when the system Reduce Motion setting is on (or the `-reduceMotion` launch flag is set for tests).
    /// Characters then stay still and use a soft highlight instead of wobbling.
    var reducedStoryMotion: Bool {
        get { self[ReducedStoryMotionKey.self] }
        set { self[ReducedStoryMotionKey.self] = newValue }
    }

    /// Characters assigned to the current page (from lesson data). Only these are drawn.
    var pageCast: [String] {
        get { self[PageCastKey.self] }
        set { self[PageCastKey.self] = newValue }
    }
}

// MARK: - Characters

/// One story character: its cut-out art and its own idle rhythm.
struct StoryCharacterArt {
    let id: String
    let name: String
    /// Transparent cut-out, trimmed so the feet touch the bottom edge.
    let cutout: String
    /// Used only if the cut-out is missing (soft oval edge, no wobble anchor needed).
    let fallback: String?
    /// Seconds per idle sway; each character differs slightly so they never move in step.
    let period: Double
    let phase: Double
    /// Idle sway in degrees, pivoting at the feet.
    let amplitude: Double
    /// Height relative to the lead character.
    let scale: CGFloat
    /// First level the character may appear in.
    let firstLevel: Int

    static let all: [String: StoryCharacterArt] = [
        // Pat: Pebble's periwinkle plush penguin with the peach scarf. Level 1.
        "pat": StoryCharacterArt(id: "pat", name: "Pat the penguin", cutout: "pat_waving_cutout", fallback: "pat_waving",
                                 period: 2.8, phase: 0, amplitude: 2.2, scale: 1, firstLevel: 1),
        // The golden puppy Pat pats. Needs its own cut-out to stand in a scene.
        "puppy": StoryCharacterArt(id: "puppy", name: "the puppy", cutout: "puppy_cutout", fallback: nil,
                                   period: 2.15, phase: 1.3, amplitude: 2.8, scale: 0.62, firstLevel: 1),
        // Pip joins in Level 2, when short i as in "sit" is taught.
        "pip": StoryCharacterArt(id: "pip", name: "Pip", cutout: "pip_cutout", fallback: nil,
                                 period: 3.25, phase: 2.1, amplitude: 2.0, scale: 0.95, firstLevel: 2),
    ]

    var hasArt: Bool { UIImage(named: cutout) != nil || fallback.map { UIImage(named: $0) != nil } == true }
}

/// Angle (degrees) of a character at time `t`: a gentle idle sway plus a brief decaying wobble after a tap.
enum Wobble {
    static func angle(at t: TimeInterval, period: Double, phase: Double, amplitude: Double, tappedAt: TimeInterval?) -> Double {
        var angle = amplitude * sin(2 * .pi * t / period + phase)
        if let tap = tappedAt {
            let dt = t - tap
            if dt >= 0 && dt < tapDuration {
                angle += 7 * exp(-dt * 5) * sin(2 * .pi * dt * 3)
            }
        }
        return angle
    }

    static let tapDuration: TimeInterval = 0.8
}

/// A cut-out that sways around its feet. Only this layer moves; text, tiles and navigation stay still.
/// Idle motion pauses when the view is offscreen or the app is not active, and stops entirely with Reduce Motion.
struct WobblingCutout: View {
    let asset: String
    let fallback: String?
    let label: String
    var period: Double = 2.8
    var phase: Double = 0
    var amplitude: Double = 2.2

    @Environment(\.reducedStoryMotion) private var reduced
    @Environment(\.scenePhase) private var scenePhase
    @State private var visible = false
    @State private var tappedAt: TimeInterval?
    @State private var glow = false

    private var hasCutout: Bool { UIImage(named: asset) != nil }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduced || !visible || scenePhase != .active)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            art
                .rotationEffect(.degrees(reduced ? 0 : Wobble.angle(at: t, period: period, phase: phase,
                                                                   amplitude: amplitude, tappedAt: tappedAt)),
                                anchor: .bottom)
        }
        .shadow(color: Palette.butterDeep.opacity(glow ? 0.9 : 0), radius: glow ? 18 : 0)
        .contentShape(Rectangle())
        .onTapGesture(perform: tap)
        .onAppear { visible = true }
        .onDisappear { visible = false }
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityValue(reduced ? "still" : "gently moving")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { tap() }
    }

    @ViewBuilder
    private var art: some View {
        if hasCutout {
            Image(asset).resizable().scaledToFit()
        } else if let fallback, UIImage(named: fallback) != nil {
            Image(fallback).resizable().scaledToFit()
                .mask(EllipticalGradient(stops: [.init(color: .black, location: 0),
                                                 .init(color: .black, location: 0.62),
                                                 .init(color: .clear, location: 0.98)],
                                         center: .center))
        } else {
            PlaceholderArt(assetName: asset, description: label)
        }
    }

    private func tap() {
        if reduced {
            // Reduce Motion: a brief soft glow instead of a wobble.
            withAnimation(.easeOut(duration: 0.15)) { glow = true }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 450_000_000)
                withAnimation(.easeIn(duration: 0.3)) { glow = false }
            }
        } else {
            tappedAt = Date().timeIntervalSinceReferenceDate
        }
    }
}

/// The page's cast standing together, feet on one line. Friends without art are left out.
struct StoryCast: View {
    @Environment(\.pageCast) private var cast

    var body: some View {
        GeometryReader { geo in
            let members = cast.compactMap { StoryCharacterArt.all[$0] }.filter(\.hasArt)
            HStack(alignment: .bottom, spacing: -geo.size.width * 0.08) {
                ForEach(members, id: \.id) { member in
                    WobblingCutout(asset: member.cutout, fallback: member.fallback, label: member.name,
                                   period: member.period, phase: member.phase, amplitude: member.amplitude)
                        .frame(width: geo.size.width * member.scale / CGFloat(max(1, members.count)) * (members.count > 1 ? 1.35 : 1),
                               height: geo.size.height * member.scale, alignment: .bottom)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
        }
    }
}
