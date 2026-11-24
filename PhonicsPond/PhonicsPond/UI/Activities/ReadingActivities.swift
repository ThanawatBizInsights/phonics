import SwiftUI

// MARK: - Page 4: which sound is at the end? (sat / tap → t or p)

struct LastSoundView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u
    let rounds: [String]
    let choices: [String]
    let context: ActivityContext

    @State private var index = 0
    @State private var answered = false
    @State private var lastWrong: String?
    @State private var loaded = false

    private var word: String { rounds[min(index, rounds.count - 1)] }
    private var lastLetter: String { String(word.last ?? " ") }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Mascot(pose: .waving)
                .frame(width: u(330), height: u(400))
                .position(x: u(300), y: u(270))

            // Only the t and p choices are shown until the child answers; then the word appears.
            if answered {
                VStack(spacing: u(18)) {
                    HStack(spacing: u(10)) {
                        ForEach(Array(word.enumerated()), id: \.offset) { offset, ch in
                            LetterTile(text: String(ch), size: 110, lit: offset == word.count - 1)
                        }
                    }
                    NextButton { next() }
                }
                .padding(u(26))
                .creamPanel(radius: 36)
                .position(x: u(830), y: u(260))
                .transition(.opacity)
            }

            VStack(spacing: u(26)) {
                Text(Prompt.whatSoundAtEnd.text)
                    .font(Typeface.child(u(44)))
                    .foregroundStyle(Palette.ink)
                    .accessibilityAddTraits(.isHeader)
                HStack(spacing: u(36)) {
                    BlueButton(title: "hear", systemImage: "speaker.wave.2.fill", height: 130) { app.playWord(word, highlight: "last.word") }
                        .playingHighlight(app.audio.isHighlighted("last.word"), radius: u(65))
                        .accessibilityLabel("hear the word")
                    ForEach(choices, id: \.self) { choice in
                        Button { choose(choice) } label: {
                            Text(choice)
                                .font(Typeface.letter(u(150)))
                                .foregroundStyle(Palette.ink)
                                .frame(width: u(290), height: u(200))
                                .background(RoundedRectangle(cornerRadius: u(34), style: .continuous)
                                    .fill(answered && choice == lastLetter ? Palette.butter : Palette.lavender))
                                .overlay(RoundedRectangle(cornerRadius: u(34), style: .continuous)
                                    .stroke(Palette.lavenderDeep, lineWidth: lastWrong == choice ? u(8) : 0))
                                .playingHighlight(app.audio.isHighlighted("last.\(choice)"), radius: u(34))
                        }
                        .buttonStyle(PressableStyle())
                        .accessibilityLabel("letter \(choice)")
                    }
                }
            }
            .padding(u(30))
            .frame(width: u(1130), height: u(350))
            .creamPanel(radius: 44)
            .position(x: u(597), y: u(625))
        }
        .animation(.easeOut(duration: 0.25), value: answered)
        .onAppear(perform: appear)
        .onDisappear { app.audio.leaveScreen() }
    }

    private func appear() {
        guard !loaded else { return }
        loaded = true
        index = min(context.initialStep, rounds.count - 1)
        context.cues.dotCount = rounds.count
        context.cues.dotIndex = index
        context.cues.replay = { app.audio.play(.whatSoundAtEnd) { app.playWord(word) } }
        if context.autoplay { app.audio.play(.whatSoundAtEnd) { app.playWord(word) } }
    }

    private func choose(_ choice: String) {
        guard !answered else { return }
        if choice == lastLetter {
            answered = true
            lastWrong = nil
            app.store.update { $0.count("lastSound.correct") }
            app.audio.play(Prompt.thatsIt.rawValue, highlight: "last.\(choice)")
        } else {
            lastWrong = choice
            app.store.update { $0.count("lastSound.retry") }
            app.audio.play(Prompt.tryLastSound.rawValue, highlight: "last.\(choice)") { app.playWord(word, highlight: "last.word") }
        }
    }

    private func next() {
        app.audio.stop()
        if index + 1 < rounds.count {
            index += 1
            answered = false
            lastWrong = nil
            context.saveStep(index)
            context.cues.dotIndex = index
            app.playWord(word, highlight: "last.word")
        } else {
            context.complete()
        }
    }
}

// MARK: - Read the words (read first; the recording and picture come after)

struct ReadWordsView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u
    let words: [String]
    let context: ActivityContext

    @State private var tappedLetters: [String: Set<Int>] = [:]
    @State private var quietElapsed = false
    @State private var quietTask: Task<Void, Never>?
    @State private var revealedWord: String?
    @State private var heardWords: Set<String> = []

    private var prompt: Prompt { words.count > 1 ? .readTheWords : .saySoundsSayWord }
    private var tileSize: CGFloat { words.count > 2 ? 78 : 100 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Mascot(pose: .waving)
                .frame(width: u(300), height: u(360))
                .position(x: u(260), y: u(250))

            if let revealedWord {
                revealCard(revealedWord)
                    .position(x: u(830), y: u(240))
                    .transition(.opacity)
            }

            VStack(spacing: u(22)) {
                Text(prompt.text)
                    .font(Typeface.child(u(40)))
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, u(30))
                    .padding(.vertical, u(8))
                    .background(Capsule().fill(Palette.butter))
                    .accessibilityAddTraits(.isHeader)
                HStack(spacing: u(22)) {
                    ForEach(words, id: \.self) { word in
                        wordCard(word)
                    }
                }
                NextButton { context.complete() }
            }
            .padding(u(26))
            .frame(width: u(1130))
            .creamPanel(radius: 44)
            .position(x: u(597), y: u(578))
        }
        .animation(.easeOut(duration: 0.25), value: revealedWord)
        .onAppear {
            context.cues.dotCount = 0
            context.cues.replay = { app.audio.play(prompt) }
            if context.autoplay { app.audio.play(prompt) }
            restartQuietTimer()
        }
        .onDisappear {
            quietTask?.cancel()
            app.audio.leaveScreen()
        }
    }

    private func wordCard(_ word: String) -> some View {
        let letters = word.map { String($0) }
        let ready = quietElapsed || (tappedLetters[word]?.count ?? 0) >= letters.count
        return VStack(spacing: u(10)) {
            HStack(spacing: u(4)) {
                ForEach(Array(letters.enumerated()), id: \.offset) { i, letter in
                    Button {
                        tappedLetters[word, default: []].insert(i)
                        restartQuietTimer()
                        app.playPhoneme(letter, highlight: "read.\(word).\(i)")
                    } label: {
                        Text(letter)
                            .font(Typeface.letter(u(tileSize)))
                            .foregroundStyle(Palette.ink)
                            .frame(minWidth: u(tileSize * 0.55))
                            .background(RoundedRectangle(cornerRadius: u(14), style: .continuous)
                                .fill(letterLit(word, i) ? Palette.butter : Color.clear))
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("letter \(letter)")
                    .accessibilityHint("Plays the sound.")
                }
            }
            HStack(spacing: u(10)) {
                // "Hear the sounds" helps decoding and is always available.
                BlueButton(title: words.count > 2 ? "" : "hear the sounds", systemImage: "waveform", height: 58, style: .cream) {
                    restartQuietTimer()
                    app.playSounds(of: word, highlightPrefix: "read.\(word).")
                }
                .accessibilityLabel("hear the sounds in \(word)")
                // "Hear the word" waits for an attempt; the meaning picture comes after it.
                BlueButton(title: words.count > 2 ? "" : "hear the word", systemImage: "speaker.wave.2.fill", height: 58, enabled: ready) {
                    app.playWord(word, highlight: "read.\(word).word") {
                        heardWords.insert(word)
                        revealedWord = word
                        app.store.update { $0.count("read.heard.\(word)") }
                    }
                }
                .accessibilityLabel("hear the word \(word)")
            }
        }
        .padding(.vertical, u(16))
        .padding(.horizontal, u(18))
        .frame(minWidth: u(words.count > 2 ? 240 : 420))
        .background(RoundedRectangle(cornerRadius: u(30), style: .continuous)
            .fill(revealedWord == word ? Palette.butter.opacity(0.6) : Palette.lavender))
        .playingHighlight(app.audio.isHighlighted("read.\(word).word"), radius: u(30))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("word card")
    }

    private func letterLit(_ word: String, _ index: Int) -> Bool {
        app.audio.isHighlighted("read.\(word).\(index)")
            || app.audio.isHighlighted("read.\(word).all")
            || app.audio.isHighlighted("read.\(word).word")
    }

    private func revealCard(_ word: String) -> some View {
        let entry = app.word(word)
        return HStack(spacing: u(20)) {
            Text(word)
                .font(Typeface.letter(u(96)))
                .foregroundStyle(Palette.ink)
            if let picture = entry?.picture {
                Illustration(assetName: picture, description: "picture for \(word)", corner: 24)
                    .frame(width: u(210), height: u(210))
            }
            if app.store.data.settings.thaiHelp, let thai = entry?.thai {
                Text(thai).font(.system(size: u(30), weight: .semibold)).foregroundStyle(Palette.ink)
            }
        }
        .padding(u(24))
        .creamPanel(radius: 36)
    }

    /// "hear the word" becomes available after 5 seconds without taps (no visible timer),
    /// or as soon as every letter in that word has been tapped.
    private func restartQuietTimer() {
        quietTask?.cancel()
        quietTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            if !Task.isCancelled { quietElapsed = true }
        }
    }
}

// MARK: - Page 5: grown-up observation (On her own / With help / Not yet)

struct GrownUpCheckView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u
    let words: [String]
    let letters: [String]
    let context: ActivityContext
    @State private var unlocked = false

    private var pronoun: String { app.store.data.settings.pronoun }
    private var thai: Bool { app.store.data.settings.thaiHelp }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if unlocked {
                marksPanel
                    .position(x: u(597), y: u(470))
            } else {
                Mascot(pose: .waving)
                    .frame(width: u(330), height: u(400))
                    .position(x: u(280), y: u(420))
                VStack(spacing: u(26)) {
                    InstructionBubble(text: Prompt.grownUpTime.text, size: 52)
                    Text("Grown-ups: hold the lock for 3 seconds.")
                        .font(.system(size: u(26), weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.ink)
                    HoldToOpenButton(size: 140, label: "Grown-up check") { unlocked = true }
                    BlueButton(title: "skip", systemImage: "forward.fill", height: 76, style: .lavender) { context.complete() }
                }
                .position(x: u(780), y: u(470))
            }
        }
        .onAppear {
            context.cues.dotCount = 0
            context.cues.replay = { app.audio.play(.grownUpTime) }
            if context.autoplay { app.audio.play(.grownUpTime) }
        }
        .onDisappear { app.audio.leaveScreen() }
    }

    private var marksPanel: some View {
        VStack(alignment: .leading, spacing: u(14)) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Grown-up check · Level 1").font(.system(size: u(32), weight: .bold, design: .rounded))
                    Text("Mark what you saw today. The app does not listen or score speech.")
                        .font(.system(size: u(20), design: .rounded)).foregroundStyle(Palette.inkSoft)
                }
                Spacer()
                BlueButton(title: "done", systemImage: "checkmark", height: 72) { context.complete() }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: u(10)) {
                    section(Skill.blending, subtitle: "Reads the word aloud", items: words)
                    section(Skill.soundRecognition, subtitle: "Says the sound when shown the letter", items: letters)
                    section(Skill.finalSoundClarity, subtitle: "Final /t/ and /p/ are clearly heard (sat, tap)", items: ["t", "p"])
                }
            }
        }
        .foregroundStyle(Palette.ink)
        .padding(u(30))
        .frame(width: u(1100), height: u(660))
        .creamPanel(radius: 40)
    }

    private func section(_ skill: Skill, subtitle: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: u(8)) {
            Text(thai ? "\(skill.title) · \(skill.thai)" : skill.title)
                .font(.system(size: u(24), weight: .bold, design: .rounded))
            Text(subtitle).font(.system(size: u(18), design: .rounded)).foregroundStyle(Palette.inkSoft)
            ForEach(items, id: \.self) { item in
                MarkRow(skill: skill, item: item, pronoun: pronoun, thai: thai)
            }
        }
        .padding(.vertical, u(6))
    }
}

/// One observation row with three large choices. Saves immediately, dated.
struct MarkRow: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u
    let skill: Skill
    let item: String
    let pronoun: String
    let thai: Bool

    private var current: Mark? { app.store.data.latestMark(level: app.level, skill: skill, item: item)?.mark }

    var body: some View {
        HStack(spacing: u(14)) {
            Text(item)
                .font(Typeface.letter(u(40)))
                .frame(width: u(120), alignment: .leading)
            ForEach(Mark.allCases) { mark in
                Button {
                    app.store.update { $0.mark(mark, skill: skill, item: item, level: app.level) }
                } label: {
                    VStack(spacing: 0) {
                        Text(mark.label(pronoun: pronoun)).font(.system(size: u(22), weight: .semibold, design: .rounded))
                        if thai { Text(mark.thai).font(.system(size: u(16))) }
                    }
                    .foregroundStyle(current == mark ? Color.white : Palette.ink)
                    .frame(width: u(250), height: u(thai ? 64 : 54))
                    .background(Capsule().fill(current == mark ? Palette.blue : Palette.lavender))
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel("\(item): \(mark.label(pronoun: pronoun))")
                .accessibilityAddTraits(current == mark ? .isSelected : [])
            }
        }
    }
}

// MARK: - Finish: pick a sticker, again, or home

struct FinishView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u
    let page: Int
    let stoppedEarly: Bool
    let cues: ScreenCues
    let onAgain: () -> Void
    let onHome: () -> Void
    @State private var picked: StickerKind?

    var body: some View {
        ZStack(alignment: .topLeading) {
            Mascot(pose: .waving)
                .frame(width: u(300), height: u(360))
                .position(x: u(250), y: u(250))
            InstructionBubble(text: stoppedEarly ? "See you next time!" : "All done!", size: 54)
                .position(x: u(760), y: u(220))

            VStack(spacing: u(22)) {
                Text(Prompt.pickASticker.text)
                    .font(Typeface.child(u(46)))
                    .foregroundStyle(Palette.ink)
                HStack(spacing: u(30)) {
                    ForEach(StickerKind.allCases) { kind in
                        Button { pick(kind) } label: {
                            Illustration(assetName: kind.assetName, description: kind.label, corner: 30)
                                .frame(width: u(250), height: u(200))
                                .overlay(RoundedRectangle(cornerRadius: u(30), style: .continuous)
                                    .stroke(Palette.butterDeep, lineWidth: picked == kind ? u(9) : 0))
                                .scaleEffect(picked == kind ? 1.06 : 1)
                                .opacity(picked == nil || picked == kind ? 1 : 0.45)
                        }
                        .buttonStyle(PressableStyle())
                        .disabled(picked != nil)
                        .accessibilityLabel(kind.label)
                        .accessibilityAddTraits(picked == kind ? .isSelected : [])
                    }
                }
                HStack(spacing: u(40)) {
                    BlueButton(title: "again", systemImage: "arrow.counterclockwise", height: 90, action: onAgain)
                        .frame(width: u(330))
                    BlueButton(title: "home", systemImage: "house.fill", height: 90, action: onHome)
                        .frame(width: u(330))
                        .accessibilityIdentifier("finishHome")
                }
            }
            .padding(u(28))
            .frame(width: u(1000))
            .creamPanel(radius: 44)
            .position(x: u(597), y: u(600))
        }
        .animation(.easeOut(duration: 0.2), value: picked)
        .onAppear {
            cues.dotCount = 0
            cues.replay = { app.audio.play(.pickASticker) }
            app.audio.play(.pickASticker)
        }
        .onDisappear { app.audio.leaveScreen() }
    }

    private func pick(_ kind: StickerKind) {
        guard picked == nil else { return }
        picked = kind
        app.store.update { $0.addSticker(kind, level: app.level, page: page) }
        app.audio.stop()
        if app.store.data.settings.chime { app.audio.playEffect(.softChime) }
    }
}
