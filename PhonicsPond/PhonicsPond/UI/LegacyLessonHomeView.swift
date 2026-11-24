import SwiftUI

/// Retired in v1.1 (Home is now Storybook / Phonics / Stickers). Kept for the old Level 1 lessons.
struct LegacyLessonHomeView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u
    @State private var invite = false
    @State private var idleTask: Task<Void, Never>?

    private var prompt: Prompt { app.hasPageInProgress ? .welcomeBack : .tapToStart }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Mascot(pose: .waving)
                .frame(width: u(430), height: u(560))
                .position(x: u(250), y: u(470))

            // Top chrome
            HoldToOpenButton(label: "Grown-ups") { app.openParentArea() }
                .position(x: u(70), y: u(64))
            Pill(text: "Phonics Pond", color: Palette.cream, size: 40)
                .position(x: u(597), y: u(64))
            SquareIconButton(systemName: "arrow.clockwise", label: "hear again", pulsing: app.audio.needsReplayCue) {
                app.audio.needsReplayCue = false
                app.audio.play(prompt)
            }
            .position(x: u(1124), y: u(64))

            todayButton
                .position(x: u(800), y: u(355))

            VStack(spacing: u(22)) {
                Pill(text: "level \(app.level) · page \(app.todayPage)")
                    .accessibilityLabel("level \(app.level), page \(app.todayPage)")
                Button {
                    app.openStickerBook()
                } label: {
                    HStack(spacing: u(14)) {
                        Image(systemName: "book").font(.system(size: u(34), weight: .bold))
                        Text("stickers").font(Typeface.child(u(38)))
                    }
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, u(36))
                    .frame(height: u(84))
                    .creamPanel(radius: 42)
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel("sticker book")
            }
            .position(x: u(800), y: u(680))
        }
        .frame(width: u(CanvasSize.width), height: u(CanvasSize.height))
        .onAppear(perform: appear)
        .onDisappear {
            idleTask?.cancel()
            app.audio.leaveScreen()
        }
    }

    private var todayButton: some View {
        Button {
            app.openToday()
        } label: {
            VStack(spacing: u(26)) {
                HStack(spacing: u(14)) {
                    ForEach(app.levelLetters, id: \.self) { letter in
                        LetterTile(text: letter, size: 112)
                    }
                }
                HStack(spacing: u(22)) {
                    Image(systemName: "play.fill").font(.system(size: u(64), weight: .bold))
                    Text("today").font(Typeface.child(u(92)))
                }
                .foregroundStyle(.white)
                .frame(width: u(520), height: u(150))
                .background(Capsule().fill(Palette.blue).shadow(color: Palette.blueDeep, radius: 0, y: u(8)))
            }
            .padding(u(30))
            .creamPanel(radius: 44)
            .pulse(invite, radius: u(44))
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("today. Level \(app.level), page \(app.todayPage). Sounds \(app.levelLetters.joined(separator: ", ")).")
    }

    private func appear() {
        // After an interruption the replay button pulses instead of speaking.
        guard !app.audio.needsReplayCue else { return }
        let firstPrompt = prompt
        idleTask?.cancel()
        idleTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            app.audio.play(firstPrompt)
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            invite = true   // a soft ring, not a moving button
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            guard !Task.isCancelled, !app.audio.isPlaying else { return }
            app.audio.play(firstPrompt) // one repeat only
        }
        app.store.update { $0.hasLaunchedBefore = true }
    }
}

/// Earned stickers. Read-only: no shop, no currency.
struct StickerBookView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u

    var body: some View {
        ZStack(alignment: .topLeading) {
            SquareIconButton(systemName: "house.fill", label: "home") { app.goHome() }
                .position(x: u(70), y: u(64))
            Pill(text: "stickers", size: 36)
                .position(x: u(597), y: u(64))

            Group {
                if app.store.data.stickers.isEmpty {
                    VStack(spacing: u(18)) {
                        Image(systemName: "star").font(.system(size: u(70)))
                        Text("Finish a page to get a sticker.")
                            .font(Typeface.child(u(36)))
                    }
                    .foregroundStyle(Palette.inkSoft)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(u(170)), spacing: u(24)), count: 5), spacing: u(24)) {
                            ForEach(app.store.data.stickers) { sticker in
                                VStack(spacing: u(6)) {
                                    Illustration(assetName: sticker.kind.assetName, description: sticker.kind.label, corner: 24)
                                        .frame(width: u(160), height: u(140))
                                    Text("page \(sticker.page)")
                                        .font(Typeface.child(u(22)))
                                        .foregroundStyle(Palette.inkSoft)
                                }
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("\(sticker.kind.label), page \(sticker.page)")
                            }
                        }
                        .padding(u(30))
                    }
                }
            }
            .frame(width: u(1080), height: u(640))
            .creamPanel(radius: 44)
            .position(x: u(597), y: u(480))
        }
        .frame(width: u(CanvasSize.width), height: u(CanvasSize.height))
    }
}
