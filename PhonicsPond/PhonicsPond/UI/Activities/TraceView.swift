import SwiftUI

/// Page 2: trace a lowercase letter in the sand tray. Reused for s, a, t and p.
struct TraceView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u
    let letters: [String]
    let context: ActivityContext

    @State private var index = 0
    @State private var tracker: TraceTracker?
    @State private var dragging = false
    @State private var loaded = false

    private let boxSize: CGFloat = 430
    private var letter: String { letters[min(index, letters.count - 1)] }
    private var complete: Bool { tracker?.isComplete ?? false }

    var body: some View {
        ZStack(alignment: .topLeading) {
            InstructionBubble(text: Prompt.traceTheLetter.text, size: 46)
                .position(x: u(720), y: u(190))

            sandTray
                .position(x: u(640), y: u(545))

            // Pat sits on the tray rim, in front of it (as in the reference)
            Mascot(pose: .waving)
                .frame(width: u(250), height: u(310))
                .position(x: u(185), y: u(290))

            letterCanvas
                .frame(width: u(boxSize), height: u(boxSize))
                .position(x: u(640), y: u(520))

            HStack(spacing: u(20)) {
                BlueButton(title: "", systemImage: "speaker.wave.2.fill", height: 110) { app.playPhoneme(letter) }
                    .accessibilityLabel("hear the sound")
                BlueButton(title: "again", systemImage: "arrow.uturn.backward", height: 80, style: .lavender) { resetTracker() }
                    .accessibilityLabel("trace again")
            }
            .position(x: u(200), y: u(760))

            NextButton(enabled: true) { next() }
                .pulse(complete, radius: u(44))
                .position(x: u(1070), y: u(760))
        }
        .onAppear(perform: appear)
        .onDisappear { app.audio.stop() }
    }

    private var sandTray: some View {
        ZStack {
            Ellipse().fill(Palette.trayBase).frame(width: u(900), height: u(500)).offset(y: u(16))
            Ellipse().fill(Palette.trayRim).frame(width: u(900), height: u(490))
            Ellipse()
                .fill(RadialGradient(colors: [Palette.sand, Palette.sandDeep], center: .center, startRadius: u(40), endRadius: u(470)))
                .frame(width: u(820), height: u(420))
        }
        .accessibilityHidden(true)
    }

    private var letterCanvas: some View {
        let size = u(boxSize)
        let current = tracker
        return Canvas { ctx, _ in
            guard let path = LetterPath.path(for: letter), let current else { return }
            // Groove (the letter shape pressed into sand)
            for stroke in path.strokes {
                var groove = Path()
                groove.addLines(stroke.map { CGPoint(x: $0.x * size, y: $0.y * size) })
                ctx.stroke(groove, with: .color(Palette.cream.opacity(0.85)),
                           style: StrokeStyle(lineWidth: size * 0.12, lineCap: .round, lineJoin: .round))
            }
            // Guide dots
            for (s, dots) in current.dots.enumerated() {
                for (d, dot) in dots.enumerated() {
                    let reached = current.isReached(stroke: s, dot: d)
                    let isStart = s == current.stroke && d == 0 && !current.isComplete
                    let r = size * (isStart ? 0.04 : 0.014)
                    let rect = CGRect(x: dot.x * size - r, y: dot.y * size - r, width: r * 2, height: r * 2)
                    let color: Color = isStart ? Palette.blue : (reached ? Palette.blue : Palette.periwinkle.opacity(0.7))
                    ctx.fill(Path(ellipseIn: rect), with: .color(color))
                }
            }
        }
        .overlay {
            if complete {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: u(70)))
                    .foregroundStyle(Palette.success)
                    .offset(x: u(190), y: -u(170))
                    .accessibilityLabel("letter traced")
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let p = CGPoint(x: value.location.x / size, y: value.location.y / size)
                    if !dragging {
                        dragging = true
                        if tracker?.begin(at: p) == true { app.playPhoneme(letter) }
                    } else {
                        let wasComplete = tracker?.isComplete ?? false
                        let strokeBefore = tracker?.stroke
                        tracker?.move(to: p)
                        if !wasComplete, tracker?.isComplete == true {
                            app.store.update { $0.count("trace.\(letter)") }
                        } else if strokeBefore != tracker?.stroke {
                            dragging = false
                        }
                    }
                }
                .onEnded { _ in
                    dragging = false
                    tracker?.end()
                }
        )
        .accessibilityElement()
        .accessibilityLabel("Tracing area for the letter \(letter). Start at the big blue dot.")
        .accessibilityAddTraits(.allowsDirectInteraction)
    }

    private func appear() {
        guard !loaded else { return }
        loaded = true
        index = min(context.initialStep, letters.count - 1)
        resetTracker()
        context.cues.dotCount = letters.count
        context.cues.dotIndex = index
        context.cues.replay = { app.audio.play(.traceTheLetter) }
        if context.autoplay { app.audio.play(.traceTheLetter) }
    }

    private func resetTracker() {
        dragging = false
        tracker = LetterPath.path(for: letter).map { TraceTracker(path: $0) }
    }

    private func next() {
        app.audio.stop()
        if index + 1 < letters.count {
            index += 1
            resetTracker()
            context.saveStep(index)
            context.cues.dotIndex = index
            app.audio.play(.traceTheLetter)
        } else {
            context.complete()
        }
    }
}
