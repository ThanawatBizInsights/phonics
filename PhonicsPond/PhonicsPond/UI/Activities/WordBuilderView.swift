import SwiftUI

/// Page 3: build "sat" with tiles (tap or drag), blend it, hear it, then change one sound to make "pat".
/// Controls stay in the same positions in every phase.
struct WordBuilderView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u
    let tray: [String]
    let build: String
    let change: String
    let context: ActivityContext

    @State private var model: WordBuilderModel
    @State private var phase: WordBuilderPhase
    @State private var attemptReady = false
    @State private var blending = false
    @State private var litSlot: Int?
    @State private var glowSlot: Int?
    @State private var helpPulse: Int?
    @State private var ghostTile: Int?
    @State private var dragTile: Int?
    @State private var dragOffset: CGSize = .zero
    @State private var waitTask: Task<Void, Never>?
    @State private var loaded = false

    // Canvas layout (1194 × 834)
    private let slotY: CGFloat = 300
    private let slotXs: [CGFloat] = [190, 400, 610]
    private let slotSize: CGFloat = 180
    private let trayY: CGFloat = 712
    private let trayTileSize: CGFloat = 132

    init(tray: [String], build: String, change: String, context: ActivityContext) {
        self.tray = tray
        self.build = build
        self.change = change
        self.context = context
        let phase = WordBuilderPhase(rawValue: context.initialStep) ?? .build
        _phase = State(initialValue: phase)
        _model = State(initialValue: WordBuilderModel.restored(tray: tray, build: build, change: change, phase: phase))
    }

    private var isReveal: Bool { phase == .buildReveal || phase == .changeReveal }
    private var currentWord: String { (phase == .build || phase == .buildReveal) ? build : change }

    private var instruction: String {
        if isReveal { return currentWord }
        if model.isComplete { return Prompt.saySoundsSayWord.text }
        return phase == .build ? Prompt.buildSat.text : Prompt.changeMakePat.text
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Left: the word panel
            RoundedRectangle(cornerRadius: u(40), style: .continuous)
                .fill(Color.clear)
                .frame(width: u(720), height: u(480))
                .creamPanel(radius: 40)
                .position(x: u(400), y: u(345))

            Text(instruction)
                .font(Typeface.child(u(isReveal ? 52 : 36)))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: u(650), height: u(70))
                .background(Capsule().fill(Palette.lavender))
                .position(x: u(400), y: u(165))
                .accessibilityAddTraits(.isHeader)

            ForEach(0..<model.slots.count, id: \.self) { slot in
                slotView(slot)
                    .position(x: u(slotXs[slot]), y: u(slotY))
            }

            if !isReveal {
                blendBar
                    .position(x: u(400), y: u(430))
            }

            BlueButton(title: "hear the word", systemImage: "speaker.wave.2.fill", height: 84,
                       enabled: model.isComplete && (attemptReady || isReveal)) { hearWord() }
                .position(x: u(400), y: u(522))

            // Right: Pat, or the meaning picture after the word has been heard
            Group {
                if isReveal {
                    VStack(spacing: u(10)) {
                        Illustration(assetName: app.word(currentWord)?.picture,
                                     description: currentWord == "sat" ? "Pat sitting on a log" : "Pat patting a puppy",
                                     corner: 32)
                            .frame(width: u(380), height: u(400))
                        if app.store.data.settings.thaiHelp, let thai = app.word(currentWord)?.thai {
                            Text(thai).font(.system(size: u(28), weight: .semibold)).foregroundStyle(Palette.ink)
                                .padding(.horizontal, u(16)).background(Capsule().fill(Palette.cream))
                        }
                    }
                } else {
                    Mascot(pose: .waving)
                        .frame(width: u(330), height: u(420))
                }
            }
            .position(x: u(960), y: u(360))

            // Bottom: tile tray (or next, after the reveal)
            RoundedRectangle(cornerRadius: u(40), style: .continuous)
                .fill(Color.clear)
                .frame(width: u(1110), height: u(170))
                .creamPanel(radius: 40)
                .position(x: u(597), y: u(trayY))

            if isReveal {
                NextButton { next() }
                    .position(x: u(597), y: u(trayY))
            } else {
                ForEach(Array(model.trayTiles.enumerated()), id: \.element.id) { offset, tile in
                    trayTileView(tile)
                        .position(x: u(trayX(offset, count: model.trayTiles.count)), y: u(trayY))
                }
                HelpButton(action: help)
                    .position(x: u(1080), y: u(trayY))
            }
        }
        .coordinateSpace(.named("builder"))
        .onAppear(perform: appear)
        .onDisappear {
            waitTask?.cancel()
            app.audio.stop()
        }
    }

    // MARK: Pieces

    private func slotView(_ slot: Int) -> some View {
        let tile = model.slots[slot]
        return Group {
            if let tile {
                LetterTile(text: tile.letter, size: slotSize, lit: litSlot == slot, glow: glowSlot == slot)
            } else {
                LetterTile(text: "", size: slotSize, dashed: true)
            }
        }
        .pulse(helpPulse == slot, radius: u(34))
        .onTapGesture { tapSlot(slot) }
        .accessibilityElement()
        .accessibilityLabel(tile.map { "\($0.letter) in the \(SlotPosition.name(slot, of: model.slots.count)) box" }
                            ?? "empty \(SlotPosition.name(slot, of: model.slots.count)) box")
        .accessibilityHint(tile == nil || isReveal ? "" : "Tap to take the tile out.")
        .accessibilityAddTraits(tile == nil ? [] : .isButton)
    }

    private var blendBar: some View {
        VStack(spacing: u(6)) {
            HStack(spacing: 0) {
                Capsule().fill(Palette.periwinkle).frame(width: u(440), height: u(10))
                Image(systemName: "arrowtriangle.right.fill")
                    .font(.system(size: u(30)))
                    .foregroundStyle(Palette.periwinkle)
                    .offset(x: -u(6))
            }
            Text("swipe to blend")
                .font(Typeface.child(u(26)))
                .foregroundStyle(Palette.inkSoft)
        }
        .frame(width: u(520), height: u(90))
        .contentShape(Rectangle())
        .opacity(model.isComplete ? 1 : 0.35)
        .gesture(DragGesture(minimumDistance: 20).onEnded { value in
            if value.translation.width > u(60) { blend() }
        })
        .onTapGesture { blend() }
        .accessibilityElement()
        .accessibilityLabel("blend the sounds")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { blend() }
    }

    private func trayTileView(_ tile: BuilderTile) -> some View {
        let isDragging = dragTile == tile.id
        return LetterTile(text: tile.letter, size: trayTileSize, fill: Palette.lavender)
            .pulse(ghostTile == tile.id, radius: u(24))
            .offset(isDragging ? dragOffset : .zero)
            .zIndex(isDragging ? 10 : 0)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named("builder"))
                    .onChanged { value in
                        dragTile = tile.id
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        let moved = hypot(value.translation.width, value.translation.height)
                        dragTile = nil
                        dragOffset = .zero
                        if moved < u(12) {
                            tapTray(tile)
                        } else if let slot = slot(near: value.location) {
                            drop(tile, in: slot)
                        }
                    }
            )
            .accessibilityElement()
            .accessibilityLabel("letter \(tile.letter)")
            .accessibilityHint("Places the letter in the next box.")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { tapTray(tile) }
    }

    private func trayX(_ offset: Int, count: Int) -> CGFloat {
        let spacing: CGFloat = 170
        let start: CGFloat = 520 - spacing * CGFloat(count - 1) / 2
        return start + spacing * CGFloat(offset)
    }

    private func slot(near point: CGPoint) -> Int? {
        let hits = slotXs.indices.map { i in (i, hypot(point.x - u(slotXs[i]), point.y - u(slotY))) }
        guard let best = hits.min(by: { $0.1 < $1.1 }), best.1 < u(150) else { return nil }
        return best.0
    }

    // MARK: Actions

    private func appear() {
        guard !loaded else { return }
        loaded = true
        context.cues.dotCount = 0
        context.cues.replay = replayInstruction
        if context.autoplay { replayInstruction() }
        if model.isComplete && !isReveal { startAttemptWait() }
    }

    private func replayInstruction() {
        if isReveal { app.playWord(currentWord); return }
        if model.isComplete { app.audio.play(.saySoundsSayWord); return }
        app.audio.play(phase == .build ? .buildSat : .changeMakePat)
    }

    private func tapTray(_ tile: BuilderTile) {
        guard !isReveal, !blending else { return }
        let outcome = model.place(tile)
        handle(outcome, letter: tile.letter)
    }

    private func drop(_ tile: BuilderTile, in slot: Int) {
        guard !isReveal, !blending else { return }
        if let existing = model.slots[slot], existing.id != tile.id { model.remove(from: slot) }
        let outcome = model.place(tile, in: slot)
        handle(outcome, letter: tile.letter)
    }

    private func handle(_ outcome: PlaceOutcome, letter: String) {
        helpPulse = nil
        ghostTile = nil
        switch outcome {
        case .noRoom:
            // Every box is full: point to the box to change ("Try the first sound.").
            if let slot = model.firstProblemSlot {
                helpPulse = slot
                app.audio.play(Prompt.tryPosition(slot, of: model.slots.count))
            }
        case .correct(let slot):
            if glowSlot == slot { glowSlot = nil }
            app.playPhoneme(letter) {
                if model.isComplete { builtWord() }
            }
        case .misplaced(let slot):
            // Calm hint: soft lavender glow, then which position to fix and the word modelled in sounds.
            glowSlot = slot
            attemptReady = false
            app.store.update { $0.count("builder.misplaced") }
            let hint = Prompt.tryPosition(slot, of: model.slots.count)
            app.playPhoneme(letter) {
                app.audio.play(hint) {
                    app.audio.play(AudioID.blend(currentWord))
                }
            }
        }
    }

    private func tapSlot(_ slot: Int) {
        guard !isReveal, !blending, model.slots[slot] != nil else { return }
        model.remove(from: slot)
        if glowSlot == slot { glowSlot = nil }
        attemptReady = false
        waitTask?.cancel()
        app.audio.stop()
    }

    private func builtWord() {
        glowSlot = nil
        helpPulse = nil
        ghostTile = nil
        if phase == .change {
            app.audio.play(.changedOneSound) { app.audio.play(.saySoundsSayWord) }
        } else {
            app.audio.play(.saySoundsSayWord)
        }
        startAttemptWait()
    }

    /// Time to try saying the word before the recording is offered. No visible timer.
    private func startAttemptWait() {
        attemptReady = false
        waitTask?.cancel()
        waitTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            if !Task.isCancelled { attemptReady = true }
        }
    }

    private func blend() {
        guard model.isComplete, !blending, !isReveal else { return }
        blending = true
        blendStep(0)
    }

    private func blendStep(_ i: Int) {
        guard i < model.slots.count, let tile = model.slots[i] else {
            litSlot = nil
            blending = false
            attemptReady = true
            return
        }
        litSlot = i
        app.playPhoneme(tile.letter) {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 150_000_000)
                blendStep(i + 1)
            }
        }
    }

    private func hearWord() {
        guard model.isComplete else { return }
        waitTask?.cancel()
        let word = currentWord
        app.playWord(word) {
            switch phase {
            case .build:
                phase = .buildReveal
                context.saveStep(phase.rawValue)
            case .change:
                phase = .changeReveal
                context.saveStep(phase.rawValue)
            default:
                break
            }
        }
    }

    private func next() {
        app.audio.stop()
        switch phase {
        case .buildReveal:
            model.retarget(to: change)
            phase = .change
            attemptReady = false
            context.saveStep(phase.rawValue)
            app.audio.play(.changeMakePat)
        case .changeReveal:
            context.complete()
        default:
            break
        }
    }

    private func help() {
        guard !isReveal else { return }
        let level = model.useHelp()
        app.store.update { $0.count("builder.help") }
        switch level {
        case 1:
            app.audio.play(AudioID.blend(currentWord))
        case 2:
            helpPulse = model.firstProblemSlot
            app.audio.play(AudioID.blend(currentWord))
        default:
            helpPulse = model.firstProblemSlot
            ghostTile = model.suggestedTile?.id
        }
    }
}
