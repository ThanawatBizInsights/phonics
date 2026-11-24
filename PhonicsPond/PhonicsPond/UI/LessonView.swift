import Observation
import SwiftUI

/// Shared between the lesson chrome and the current activity.
@Observable
final class ScreenCues {
    /// Replays the current screen's instruction (top-right button).
    @ObservationIgnored var replay: (() -> Void)?
    var dotIndex = 0
    var dotCount = 0
}

/// What an activity needs from its page.
struct ActivityContext {
    let page: Int
    let initialStep: Int
    /// False when returning to a saved activity: nothing plays until the child taps.
    let autoplay: Bool
    let cues: ScreenCues
    let saveStep: (Int) -> Void
    let complete: () -> Void
}

/// One page: stone picker, then the five stages, with home/replay chrome and pause/resume.
struct LessonView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u
    let page: Int
    let resume: Bool

    @State private var stage: Int?          // nil = stone picker
    @State private var step = 0
    @State private var autoplay = true
    @State private var showStop = false
    @State private var stoppedEarly = false
    @State private var cues = ScreenCues()
    @State private var started = false

    private var lessonPage: LessonPage? { app.plan.page(page) }
    private var finishIndex: Int { (lessonPage?.stages.count ?? 5) - 1 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let lessonPage {
                content(lessonPage)
                    .frame(width: u(CanvasSize.width), height: u(CanvasSize.height))
            }
            chrome
            if showStop { stopDialog }
        }
        .frame(width: u(CanvasSize.width), height: u(CanvasSize.height))
        .environment(\.pageCast, lessonPage?.castIDs ?? ["pat"])
        .onAppear(perform: start)
        .onDisappear { app.audio.leaveScreen() }
    }

    // MARK: Content

    @ViewBuilder
    private func content(_ lessonPage: LessonPage) -> some View {
        if let stage, lessonPage.stages.indices.contains(stage) {
            let activity = lessonPage.stages[stage].activity
            let context = ActivityContext(page: page, initialStep: step, autoplay: autoplay, cues: cues,
                                          saveStep: { saveStep($0) }, complete: { completeStage() })
            Group {
                if case .finish = activity {
                    FinishView(page: page, stoppedEarly: stoppedEarly, cues: cues,
                               onAgain: restart, onHome: { app.goHome() })
                } else {
                    ActivityHost(activity: activity, context: context)
                }
            }
            .id("stage-\(stage)-\(stoppedEarly)")
        } else {
            StonePickerView(page: page, autoplay: autoplay, cues: cues, onPick: pick)
        }
    }

    private var chrome: some View {
        ZStack(alignment: .topLeading) {
            SquareIconButton(systemName: "house.fill", label: "home", action: requestHome)
                .accessibilityIdentifier("chromeHome")
                .position(x: u(70), y: u(64))
            VStack(spacing: u(10)) {
                Pill(text: "level \(app.level) · page \(page)")
                    .accessibilityLabel("level \(app.level), page \(page)")
                if cues.dotCount > 1 {
                    HStack(spacing: u(10)) {
                        ForEach(0..<cues.dotCount, id: \.self) { i in
                            Circle()
                                .fill(i <= cues.dotIndex ? Palette.ink : Palette.lavenderDeep)
                                .frame(width: u(16), height: u(16))
                        }
                    }
                    .padding(.horizontal, u(16))
                    .padding(.vertical, u(8))
                    .background(Capsule().fill(Palette.cream.opacity(0.9)))
                    .accessibilityElement()
                    .accessibilityLabel("\(cues.dotIndex + 1) of \(cues.dotCount)")
                }
            }
            .position(x: u(597), y: u(cues.dotCount > 1 ? 82 : 64))
            SquareIconButton(systemName: "arrow.clockwise", label: "hear again", pulsing: app.audio.needsReplayCue) {
                app.audio.needsReplayCue = false
                cues.replay?()
            }
            .position(x: u(1124), y: u(64))
        }
    }

    private var stopDialog: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
                .onTapGesture { showStop = false }
            VStack(spacing: u(30)) {
                Text(Prompt.stopForToday.text)
                    .font(Typeface.child(u(48)))
                    .foregroundStyle(Palette.ink)
                HStack(spacing: u(30)) {
                    BlueButton(title: "stop", systemImage: "hand.raised.fill", height: 100, style: .lavender) { stopForToday() }
                    BlueButton(title: "keep going", systemImage: "play.fill", height: 100) { showStop = false }
                }
            }
            .padding(u(50))
            .creamPanel(radius: 44)
        }
        .frame(width: u(CanvasSize.width), height: u(CanvasSize.height))
    }

    // MARK: Flow

    private func start() {
        guard !started else { return }
        started = true
        let saved = app.store.data.progress(level: app.level, page: page)
        if resume, saved.started, !saved.done, saved.stage < finishIndex {
            // Return to the saved activity. No autoplay: replay pulses instead.
            stage = saved.stage
            step = saved.step
            autoplay = false
            app.audio.needsReplayCue = true
        } else {
            app.store.update { $0.startPage(level: app.level, page: page) }
            stage = nil
            step = 0
            autoplay = !app.audio.needsReplayCue
        }
    }

    private func pick(_ index: Int) {
        app.audio.stop()
        let saved = app.store.data.progress(level: app.level, page: page)
        step = (saved.stage == index && index != finishIndex) ? saved.step : 0
        autoplay = true
        stage = index
        if index == finishIndex {
            enterFinish(early: false)
        } else {
            app.store.update { $0.setPosition(level: app.level, page: page, stage: index, step: step) }
        }
    }

    private func saveStep(_ newStep: Int) {
        guard let stage else { return }
        step = newStep
        app.store.update { $0.setPosition(level: app.level, page: page, stage: stage, step: newStep) }
    }

    private func completeStage() {
        guard let current = stage else { return }
        app.audio.stop()
        app.store.update { $0.completeStage(level: app.level, page: page, stage: current) }
        // Soft chime for a completed activity. The next screen's instruction waits for it to finish.
        if app.store.data.settings.chime { app.audio.playEffect(.softChime) }
        let next = current + 1
        autoplay = true
        step = 0
        cues.dotCount = 0
        if next >= finishIndex {
            stage = finishIndex
            enterFinish(early: false)
        } else {
            stage = next
            app.store.update { $0.setPosition(level: app.level, page: page, stage: next, step: 0) }
        }
    }

    private func enterFinish(early: Bool) {
        stoppedEarly = early
        cues.dotCount = 0
        let done = app.store.data.progress(level: app.level, page: page).completedStages
        let completed = !early && (0..<finishIndex).allSatisfy(done.contains)
        app.store.update { $0.finishPage(level: app.level, page: page, completed: completed) }
    }

    private func requestHome() {
        guard let stage, stage != finishIndex else {
            app.goHome()
            return
        }
        app.audio.play(.stopForToday)
        showStop = true
    }

    /// "Stop for today": keeps the saved position, still offers a sticker.
    private func stopForToday() {
        showStop = false
        app.audio.stop()
        autoplay = true
        stage = finishIndex
        enterFinish(early: true)
    }

    private func restart() {
        app.audio.stop()
        app.store.update { $0.restartPage(level: app.level, page: page) }
        stoppedEarly = false
        step = 0
        autoplay = true
        cues.dotCount = 0
        stage = nil
    }
}

/// Routes an activity to its screen.
struct ActivityHost: View {
    let activity: Activity
    let context: ActivityContext

    var body: some View {
        switch activity {
        case .pictureTap(let words):
            PictureTapView(words: words, context: context)
        case .soundCards(let letters):
            SoundCardsView(letters: letters, context: context)
        case .reviewSounds(let letters):
            ReviewSoundsView(letters: letters, context: context)
        case .offlineCard(let kind):
            OfflineCardView(kind: kind, context: context)
        case .oralBlend(let words):
            OralBlendView(words: words, context: context)
        case .trace(let letters):
            TraceView(letters: letters, context: context)
        case .wordBuilder(let tray, let build, let change):
            WordBuilderView(tray: tray, build: build, change: change, context: context)
        case .lastSound(let rounds, let choices):
            LastSoundView(rounds: rounds, choices: choices, context: context)
        case .readWords(let words):
            ReadWordsView(words: words, context: context)
        case .grownUpCheck(let words, let letters):
            GrownUpCheckView(words: words, letters: letters, context: context)
        case .finish:
            EmptyView()
        }
    }
}

/// The five stepping stones with the open pond above. Any stone can be chosen.
struct StonePickerView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u
    let page: Int
    let autoplay: Bool
    let cues: ScreenCues
    let onPick: (Int) -> Void

    private var stages: [LessonStage] { app.plan.page(page)?.stages ?? [] }
    private var progress: PageProgress { app.store.data.progress(level: app.level, page: page) }
    private var nextStone: Int { stages.indices.first { !progress.completedStages.contains($0) } ?? 0 }
    private var intro: String { app.plan.page(page)?.intro ?? Prompt.tapGlowingStone.rawValue }
    @State private var gate = TapGate()
    private var introText: String { Prompt(rawValue: intro)?.text ?? "" }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Mascot(pose: .waving)
                .frame(width: u(300), height: u(380))
                .position(x: u(230), y: u(290))

            InstructionBubble(text: introText, size: 38)
                .position(x: u(700), y: u(210))

            pageChips
                .position(x: u(700), y: u(330))

            HStack(alignment: .top, spacing: u(22)) {
                ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                    stoneButton(index: index, stone: stage.stone)
                }
            }
            .position(x: u(597), y: u(650))
        }
        .onAppear {
            cues.dotCount = 0
            cues.replay = { app.audio.play(intro) }
            if autoplay { app.audio.play(intro) }
        }
    }

    private var pageChips: some View {
        HStack(spacing: u(12)) {
            Text("pages")
                .font(Typeface.child(u(24)))
                .foregroundStyle(Palette.inkSoft)
            ForEach(app.plan.pages, id: \.page) { p in
                let done = app.store.data.progress(level: app.level, page: p.page).done
                Button {
                    if p.page != page { app.openPage(p.page) }
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Text("\(p.page)")
                            .font(Typeface.child(u(30)))
                            .foregroundStyle(Palette.ink)
                            .frame(width: u(64), height: u(64))
                            .background(Circle().fill(p.page == page ? Palette.butter : Palette.cream))
                            .overlay(Circle().stroke(Palette.creamEdge, lineWidth: u(3)))
                        if done {
                            Image(systemName: "star.fill")
                                .font(.system(size: u(20)))
                                .foregroundStyle(Palette.butterDeep)
                                .offset(x: u(6), y: -u(6))
                        }
                    }
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel("page \(p.page)\(done ? ", done" : "")\(p.page == page ? ", current" : "")")
            }
        }
        .padding(.horizontal, u(20))
        .padding(.vertical, u(10))
        .background(Capsule().fill(Palette.cream.opacity(0.85)))
    }

    private func stoneButton(index: Int, stone: Stone) -> some View {
        let isNext = index == nextStone
        let isDone = progress.completedStages.contains(index)
        return Button {
            if gate.allow() { onPick(index) }
        } label: {
            VStack(spacing: u(14)) {
                ZStack(alignment: .bottom) {
                    Ellipse()
                        .fill(isNext ? Palette.blue.opacity(0.85) : (index % 2 == 0 ? Palette.lavender : Palette.cream))
                        .frame(width: u(190), height: u(160))
                        .shadow(color: .black.opacity(0.15), radius: u(6), y: u(6))
                    Image(systemName: stone.systemImage)
                        .font(.system(size: u(64), weight: .semibold))
                        .foregroundStyle(isNext ? Color.white : Palette.periwinkle)
                        .frame(width: u(190), height: u(160))
                    if isNext {
                        Image(systemName: "play.fill")
                            .font(.system(size: u(22), weight: .bold))
                            .foregroundStyle(.white)
                            .padding(u(10))
                            .background(Circle().fill(Palette.blueDeep))
                            .offset(y: u(18))
                    } else if isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: u(22), weight: .bold))
                            .foregroundStyle(.white)
                            .padding(u(10))
                            .background(Circle().fill(Palette.success))
                            .offset(y: u(18))
                    }
                }
                .pulse(isNext, radius: u(80))
                Text(stone.label)
                    .font(Typeface.child(u(34)))
                    .foregroundStyle(Palette.ink)
                    .frame(width: u(190), height: u(64))
                    .background(Capsule().fill(Palette.cream))
            }
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("\(stone.label)\(isDone ? ", done" : "")\(isNext ? ", next" : "")")
    }
}
