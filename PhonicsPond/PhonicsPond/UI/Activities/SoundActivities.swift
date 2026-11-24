import SwiftUI

// MARK: - Picture tap warm-up (listening only: object names are spoken, never printed)

struct PictureTapView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u
    let words: [String]
    let context: ActivityContext
    @State private var heard: Set<String> = []

    var body: some View {
        ZStack(alignment: .topLeading) {
            Mascot(pose: .waving)
                .frame(width: u(290), height: u(340))
                .position(x: u(215), y: u(250))
            VStack(spacing: u(16)) {
                Pill(text: "ears warm-up", color: Palette.lavender, size: 28)
                InstructionBubble(text: Prompt.tapAPicture.text, size: 50)
            }
            .position(x: u(700), y: u(250))

            HStack(spacing: u(34)) {
                ForEach(words, id: \.self) { word in
                    let entry = app.word(word)
                    Button {
                        heard.insert(word)
                        app.playWord(word, highlight: "pic.\(word)")
                    } label: {
                        Illustration(assetName: entry?.picture, description: "picture of a \(word)", corner: 30)
                            .frame(width: u(300), height: u(230))
                            .overlay(alignment: .topTrailing) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: u(26), weight: .bold))
                                    .foregroundStyle(Palette.blue)
                                    .padding(u(12))
                                    .background(Circle().fill(Color.white.opacity(0.9)))
                                    .padding(u(12))
                            }
                            .playingHighlight(app.audio.isHighlighted("pic.\(word)"), radius: u(30))
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("picture: \(word)")
                    .accessibilityHint("Plays the word.")
                }
            }
            .frame(width: u(1130), height: u(330))
            .creamPanel(radius: 44)
            .position(x: u(597), y: u(600))

            NextButton(enabled: heard.count >= min(2, words.count)) { context.complete() }
                .opacity(heard.count >= min(2, words.count) ? 1 : 0)
                .position(x: u(1060), y: u(770))
        }
        .onAppear {
            context.cues.dotCount = 0
            context.cues.replay = { app.audio.play(.tapAPicture) }
            if context.autoplay { app.audio.play(.tapAPicture) }
        }
        .onDisappear { app.audio.leaveScreen() }
    }
}

// MARK: - Sound cards (s, a, t, p)

struct SoundCardsView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u
    let letters: [String]
    let context: ActivityContext

    @State private var index = 0
    @State private var playedOnce = false
    private var playing: Bool { app.audio.isHighlighted("card.\(letter)") }
    @State private var yourTurn = false
    @State private var showTip = false
    @State private var helpTaps = 0
    @State private var loaded = false

    private var letter: String { letters[min(index, letters.count - 1)] }
    private var cue: SoundCue { SoundCue.forLetter(letter) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Mascot(pose: .waving)
                .frame(width: u(230), height: u(300))
                .position(x: u(120), y: u(480))

            VStack(spacing: u(18)) {
                Text(Prompt.tapToHearSound.text)
                    .font(Typeface.child(u(40)))
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, u(14))
                    .background(RoundedRectangle(cornerRadius: u(24)).fill(Palette.cream))
                    .accessibilityAddTraits(.isHeader)
                HStack(spacing: u(22)) {
                    VStack(spacing: u(18)) {
                        Button(action: playSound) {
                            Text(letter)
                                .font(Typeface.letter(u(260)))
                                .foregroundStyle(Palette.ink)
                                .frame(width: u(390), height: u(300))
                                .background(RoundedRectangle(cornerRadius: u(34), style: .continuous).fill(Palette.cream))
                                .overlay(RoundedRectangle(cornerRadius: u(34), style: .continuous)
                                    .stroke(playing ? Palette.periwinkle : Palette.lavender, lineWidth: u(playing ? 12 : 6)))
                                .shadow(color: playing ? Palette.lavenderDeep : .clear, radius: u(16))
                        }
                        .buttonStyle(PressableStyle())
                        .accessibilityLabel("letter \(letter)")
                        .accessibilityHint("Plays the sound.")
                        BlueButton(title: "hear", systemImage: "speaker.wave.2.fill", height: 88, action: playSound)
                    }
                    VStack(spacing: u(16)) {
                        cueCard(asset: cue.mouthAsset, caption: cue.mouthCaption, kind: "mouth picture")
                            .frame(height: u(205))
                        cueCard(asset: cue.actionAsset, caption: cue.actionCaption, kind: "action")
                            .frame(height: u(205))
                    }
                }
            }
            .padding(u(22))
            .frame(width: u(900), height: u(548))
            .creamPanel(radius: 44)
            .position(x: u(700), y: u(408))

            HStack(spacing: u(30)) {
                HStack(spacing: u(12)) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: u(36)))
                    Text("your turn").font(Typeface.child(u(40)))
                }
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, u(34))
                .frame(height: u(88))
                .background(Capsule().fill(yourTurn ? Palette.butter : Palette.lavender))
                .pulse(yourTurn, radius: u(44))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("your turn: say the sound")

                NextButton(enabled: playedOnce) { next() }
                    .opacity(playedOnce ? 1 : 0.35)
                HelpButton(action: help)
            }
            .padding(.horizontal, u(28))
            .frame(width: u(1000), height: u(112))
            .creamPanel(radius: 40)
            .position(x: u(650), y: u(758))

            if showTip { tipSheet }
        }
        .onAppear(perform: appear)
        .onDisappear { app.audio.leaveScreen() }
    }

    private func cueCard(asset: String, caption: String, kind: String) -> some View {
        VStack(spacing: u(6)) {
            Illustration(assetName: asset, description: "\(letter): \(caption)", corner: 24)
                .frame(width: u(380), height: u(165))
                .onTapGesture { if let p = AudioID.cue(for: letter) { app.audio.play(p) } }
            Text(caption)
                .font(Typeface.child(u(26)))
                .foregroundStyle(Palette.inkSoft)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(kind): \(caption)")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { if let p = AudioID.cue(for: letter) { app.audio.play(p) } }
    }

    private var tipSheet: some View {
        ZStack {
            Color.black.opacity(0.2).onTapGesture { showTip = false }
            VStack(alignment: .leading, spacing: u(14)) {
                Text("For grown-ups").font(.system(size: u(26), weight: .bold, design: .rounded))
                Text(GrownUpTips.soundCard(letter))
                    .font(.system(size: u(24), design: .rounded))
                if app.store.data.settings.thaiHelp {
                    Text(GrownUpTips.soundCardThai(letter))
                        .font(.system(size: u(24)))
                }
                BlueButton(title: "close", height: 70) { showTip = false }
                    .frame(maxWidth: .infinity)
            }
            .foregroundStyle(Palette.ink)
            .padding(u(36))
            .frame(width: u(700))
            .creamPanel(radius: 36)
        }
        .frame(width: u(CanvasSize.width), height: u(CanvasSize.height))
    }

    private func appear() {
        guard !loaded else { return }
        loaded = true
        index = min(context.initialStep, letters.count - 1)
        updateDots()
        context.cues.replay = { app.audio.play(.tapToHearSound) }
        if context.autoplay { app.audio.play(.tapToHearSound) }
    }

    private func updateDots() {
        context.cues.dotCount = letters.count
        context.cues.dotIndex = index
    }

    private func playSound() {
        let first = !playedOnce
        app.playPhoneme(letter, highlight: "card.\(letter)") {
            playedOnce = true
            guard first, let cuePrompt = AudioID.cue(for: letter) else { return }
            app.audio.play(cuePrompt) {
                app.audio.play(.yourTurn) {
                    yourTurn = true
                    // A quiet moment for the child to say the sound. No microphone.
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 4_000_000_000)
                        yourTurn = false
                    }
                }
            }
        }
    }

    private func help() {
        helpTaps += 1
        if helpTaps % 2 == 1 {
            playSound()
        } else {
            app.audio.stop()
            showTip = true
        }
    }

    private func next() {
        app.audio.stop()
        if index + 1 < letters.count {
            index += 1
            playedOnce = false
            yourTurn = false
            helpTaps = 0
            context.saveStep(index)
            updateDots()
            app.audio.play(.tapToHearSound)
        } else {
            context.complete()
        }
    }
}

enum GrownUpTips {
    static func soundCard(_ letter: String) -> String {
        switch letter {
        case "s": return "Hold a long, gentle /s/ like a snake. Teeth close together. No \"uh\" at the end."
        case "a": return "Short /æ/ as in sat. Open the mouth wide and keep it quick, not a long แอ."
        case "t": return "Short, crisp /t/. The tongue taps behind the top teeth. Feel a puff of air on the hand."
        case "p": return "Short, crisp /p/. Lips together, then pop. A tissue in front of the mouth should move."
        default: return ""
        }
    }

    static func soundCardThai(_ letter: String) -> String {
        switch letter {
        case "s": return "ลากเสียง /s/ ยาวๆ เบาๆ เหมือนงูขู่ ฟันชิดกัน ไม่เติมเสียง \"เออ\" ท้าย"
        case "a": return "เสียง /æ/ สั้นๆ แบบในคำ sat อ้าปากกว้าง ไม่ลากยาวเป็น แอ"
        case "t": return "เสียง /t/ สั้นและชัด ลิ้นแตะหลังฟันบนแล้วปล่อย จะรู้สึกมีลมออกมาที่มือ"
        case "p": return "เสียง /p/ สั้นและชัด ปิดปากแล้วเปิดออก กระดาษทิชชูหน้าปากควรขยับ"
        default: return ""
        }
    }
}

// MARK: - Review sounds (ears stone on pages 2–5)

struct ReviewSoundsView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u
    let letters: [String]
    let context: ActivityContext
    @State private var tapped: Set<String> = []

    var body: some View {
        ZStack(alignment: .topLeading) {
            Mascot(pose: .waving)
                .frame(width: u(290), height: u(340))
                .position(x: u(215), y: u(250))
            VStack(spacing: u(16)) {
                Pill(text: "ears", color: Palette.lavender, size: 28)
                InstructionBubble(text: Prompt.tapToHearSound.text, size: 46)
            }
            .position(x: u(700), y: u(250))

            HStack(spacing: u(30)) {
                ForEach(letters, id: \.self) { letter in
                    Button {
                        tapped.insert(letter)
                        app.playPhoneme(letter, highlight: "review.\(letter)")
                    } label: {
                        LetterTile(text: letter, size: 190, fill: Palette.lavender, lit: app.audio.isHighlighted("review.\(letter)"))
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("letter \(letter)")
                    .accessibilityHint("Plays the sound.")
                }
            }
            .frame(width: u(1130), height: u(340))
            .creamPanel(radius: 44)
            .position(x: u(597), y: u(615))

            NextButton(enabled: tapped.count >= 2) { context.complete() }
                .opacity(tapped.count >= 2 ? 1 : 0)
                .position(x: u(1060), y: u(770))
        }
        .onAppear {
            context.cues.dotCount = 0
            context.cues.replay = { app.audio.play(.tapToHearSound) }
            if context.autoplay { app.audio.play(.tapToHearSound) }
        }
        .onDisappear { app.audio.leaveScreen() }
    }
}

// MARK: - Optional offline activity (sound hunt) — read by a grown-up, no audio

struct OfflineCardView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u
    let kind: OfflineCardKind
    let context: ActivityContext

    var body: some View {
        ZStack(alignment: .topLeading) {
            Mascot(pose: .waving)
                .frame(width: u(260), height: u(320))
                .position(x: u(190), y: u(300))

            VStack(alignment: .leading, spacing: u(18)) {
                HStack {
                    Pill(text: "optional · away from the screen", color: Palette.lavender, size: 26)
                    Spacer()
                }
                Text(OfflineCards.title(kind))
                    .font(.system(size: u(40), weight: .bold, design: .rounded))
                Text(OfflineCards.steps(kind))
                    .font(.system(size: u(27), design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
                if app.store.data.settings.thaiHelp {
                    Text(OfflineCards.stepsThai(kind))
                        .font(.system(size: u(25)))
                        .fixedSize(horizontal: false, vertical: true)
                }
                if kind == .soundHunt {
                    HStack(spacing: u(18)) {
                        ForEach(["sock", "pen", "pot"], id: \.self) { word in
                            Button { app.playWord(word) } label: {
                                Illustration(assetName: app.word(word)?.picture, description: "picture of a \(word)", corner: 20)
                                    .frame(width: u(150), height: u(120))
                            }
                            .buttonStyle(PressableStyle())
                            .accessibilityLabel("picture: \(word)")
                        }
                    }
                }
            }
            .foregroundStyle(Palette.ink)
            .padding(u(36))
            .frame(width: u(820), alignment: .leading)
            .creamPanel(radius: 44)
            .position(x: u(740), y: u(430))

            HStack(spacing: u(30)) {
                BlueButton(title: "skip", systemImage: "forward.fill", height: 92, style: .lavender) { context.complete() }
                BlueButton(title: "done", systemImage: "checkmark", height: 92) {
                    app.store.update { $0.count("offline.\(kind.rawValue)") }
                    context.complete()
                }
            }
            .position(x: u(740), y: u(770))
        }
        .onAppear {
            context.cues.dotCount = 0
            context.cues.replay = nil
        }
        .onDisappear { app.audio.leaveScreen() }
    }
}

enum OfflineCards {
    static func title(_ kind: OfflineCardKind) -> String {
        switch kind {
        case .soundHunt: return "Sound hunt"
        case .tissueGame: return "Tissue game"
        }
    }

    static func steps(_ kind: OfflineCardKind) -> String {
        switch kind {
        case .soundHunt:
            return "Walk around the house together. Find 3 things that start with /s/ (sock, spoon, soap) and 3 that start with /p/ (pen, pot, pillow). Say the first sound, then the word: sss… sock."
        case .tissueGame:
            return "Hold a tissue in front of your child's mouth. Say \"tap\" and \"pat\" together. Make the tissue move on the last sound. Thai words often end with a silent /t/ or /p/, so listen for the puff."
        }
    }

    static func stepsThai(_ kind: OfflineCardKind) -> String {
        switch kind {
        case .soundHunt:
            return "เดินหาของในบ้านด้วยกัน หาของ 3 อย่างที่ขึ้นต้นด้วยเสียง /s/ และ 3 อย่างที่ขึ้นต้นด้วยเสียง /p/ พูดเสียงแรกก่อน แล้วค่อยพูดคำ"
        case .tissueGame:
            return "ถือกระดาษทิชชูไว้หน้าปากลูก พูดคำว่า tap และ pat ด้วยกัน ให้กระดาษขยับตอนเสียงสุดท้าย"
        }
    }
}

// MARK: - Oral blending (hear s–a–t, say the word, then hear it)

struct OralBlendView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u
    let words: [String]
    let context: ActivityContext
    @State private var index = 0
    @State private var blendHeard = false
    @State private var canHearWord = false
    @State private var revealed = false
    @State private var loaded = false
    @State private var waitTask: Task<Void, Never>?

    private var word: String { words[min(index, words.count - 1)] }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Mascot(pose: .waving)
                .frame(width: u(250), height: u(300))
                .position(x: u(170), y: u(230))
            InstructionBubble(text: Prompt.listenWhatWord.text, size: 44)
                .position(x: u(720), y: u(190))

            HStack(spacing: u(40)) {
                BlueButton(title: "hear the sounds", systemImage: "waveform", height: 100, action: playBlend)
                    .playingHighlight(app.audio.isHighlighted("blend.all") || app.audio.currentID?.hasPrefix("phoneme_") == true, radius: u(50))

                ZStack {
                    RoundedRectangle(cornerRadius: u(34), style: .continuous)
                        .fill(revealed ? Palette.cream : Palette.lavender)
                    if revealed {
                        HStack(spacing: u(24)) {
                            Text(word)
                                .font(Typeface.letter(u(120)))
                                .foregroundStyle(Palette.ink)
                            if let picture = app.word(word)?.picture {
                                Illustration(assetName: picture, description: "picture for \(word)", corner: 24)
                                    .frame(width: u(220), height: u(220))
                            }
                        }
                    } else {
                        Text("?")
                            .font(Typeface.letter(u(150)))
                            .foregroundStyle(Palette.periwinkle)
                    }
                }
                .frame(width: u(560), height: u(300))
                .accessibilityElement(children: .combine)
                .accessibilityLabel(revealed ? "the word \(word)" : "mystery word")
            }
            .padding(u(30))
            .creamPanel(radius: 44)
            .position(x: u(710), y: u(500))

            HStack(spacing: u(30)) {
                BlueButton(title: "hear the word", systemImage: "speaker.wave.2.fill", height: 92, enabled: canHearWord) {
                    app.playWord(word, highlight: "oral.word") { revealed = true }
                }
                .playingHighlight(app.audio.isHighlighted("oral.word"), radius: u(46))
                NextButton(enabled: revealed) { next() }
                    .opacity(revealed ? 1 : 0)
            }
            .position(x: u(710), y: u(760))
        }
        .onAppear(perform: appear)
        .onDisappear {
            waitTask?.cancel()
            app.audio.leaveScreen()
        }
    }

    private func appear() {
        guard !loaded else { return }
        loaded = true
        index = min(context.initialStep, words.count - 1)
        context.cues.dotCount = words.count
        context.cues.dotIndex = index
        context.cues.replay = { app.audio.play(.listenWhatWord) }
        if context.autoplay { app.audio.play(.listenWhatWord) { playBlend() } }
    }

    private func playBlend() {
        app.playSounds(of: word, highlightPrefix: "blend.") {
            blendHeard = true
            // Time to try saying the word before the recording is offered.
            waitTask?.cancel()
            waitTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                if !Task.isCancelled { canHearWord = true }
            }
        }
    }

    private func next() {
        app.audio.stop()
        waitTask?.cancel()
        if index + 1 < words.count {
            index += 1
            blendHeard = false
            canHearWord = false
            revealed = false
            context.saveStep(index)
            context.cues.dotIndex = index
            app.audio.play(.listenWhatWord) { playBlend() }
        } else {
            context.complete()
        }
    }
}
