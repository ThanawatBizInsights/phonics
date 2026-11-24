import Foundation
import Observation

/// App-wide state: content, saved progress, audio and the current screen.
@MainActor
@Observable
final class AppModel {
    enum Route: Equatable {
        case home
        case shelf
        case story(bookID: String, page: Int)
        case phonics(level: Int)
        case sound(level: Int, tileID: String)
        case stickers
        case trophies
        // Retired from navigation in v1.1 (kept so the old Level 1 lesson code still builds).
        case lesson(page: Int, resume: Bool)
        case stickerBook
    }

    var route: Route = .home
    var showParentArea = false
    /// Changes every time a lesson is opened, so a fresh lesson view is built.
    private(set) var lessonSession = 0

    let level = 1
    let curriculum: Curriculum
    let plan: LessonPlan
    let store: ProgressStore
    let audio: AudioPlayer
    let music: MusicPlayer
    let library: StoryLibrary
    let phonicsCatalog: PhonicsCatalog
    /// Content problems found at launch (shown in the grown-up area; should be empty).
    let contentIssues: [EligibilityIssue]

    init(store: ProgressStore = ProgressStore(), bundle: Bundle = .main) {
        do {
            curriculum = try Curriculum.load(from: bundle)
            plan = try LessonPlan.load(level: 1, bundle: bundle)
            library = try StoryLibrary.load(from: bundle)
            phonicsCatalog = try PhonicsCatalog.load(from: bundle)
        } catch {
            fatalError("Phonics Pond content failed to load: \(error)")
        }
        self.store = store
        #if DEBUG
        // UI tests start from a clean device state.
        if ProcessInfo.processInfo.arguments.contains("-uiTestReset") { store.reset() }
        #endif
        audio = AudioPlayer(bundle: bundle)
        music = MusicPlayer(enabled: store.data.settings.musicOn, bundle: bundle)
        contentIssues = EligibilityValidator.validate(curriculum) + EligibilityValidator.validate(plan, against: curriculum)
        #if DEBUG
        for issue in contentIssues { print("[content] \(issue)") }
        #endif
        audio.effectsEnabled = store.data.settings.chime
        // Background music ducks while teaching audio plays (ready for the voice recordings).
        let music = self.music
        audio.onSpeechChange = { speaking in music.duck(speaking) }
    }

    var levelDefinition: LevelDefinition? { curriculum.level(level) }
    var levelLetters: [String] { levelDefinition?.graphemes.map(\.grapheme) ?? [] }
    var pageCount: Int { plan.pages.count }
    var todayPage: Int { store.data.todayPage(level: level, pageCount: pageCount) }
    var hasPageInProgress: Bool { store.data.pageInProgress(level: level, pageCount: pageCount) != nil }

    /// Home's one big button.
    func openToday() {
        openPage(todayPage)
    }

    func openPage(_ page: Int) {
        audio.stop()
        audio.needsReplayCue = false   // a deliberate tap, not a return from an interruption
        lessonSession += 1
        route = .lesson(page: page, resume: store.data.isResuming(level: level, page: page))
    }

    func goHome() {
        audio.stop()
        audio.needsReplayCue = false
        route = .home
    }

    func openStickerBook() {
        audio.stop()
        route = .stickerBook
    }

    func openParentArea() {
        audio.stop()
        showParentArea = true
    }

    // MARK: Storybook, Phonics, Stickers (v1.1)

    func openShelf() {
        audio.stop()
        route = .shelf
    }

    /// Opens a book at a page (clamped), saving the position.
    func openStory(_ bookID: String, page: Int? = nil) {
        guard let book = library.book(id: bookID), store.data.isUnlocked(book, in: library) else { return }
        audio.stop()
        let target = min(max(page ?? store.data.book(bookID).lastPage, 0), book.pages.count - 1)
        store.update { $0.setStoryPosition(bookID: bookID, page: target) }
        route = .story(bookID: bookID, page: target)
    }

    /// The book and page "Continue story" opens: the last book read, else Level 1.
    var continueBookID: String {
        if let id = store.data.lastBook, let book = library.book(id: id), store.data.isUnlocked(book, in: library) { return id }
        return library.book(level: 1)?.id ?? "book.l1"
    }

    /// "Level 1 · Page 3" for the Home card, when a book has been started.
    var storyProgressLine: String? {
        guard let id = store.data.lastBook, let book = library.book(id: id) else { return nil }
        return "Level \(book.level) · Page \(store.data.book(id).lastPage + 1)"
    }

    func openPhonics(level: Int? = nil) {
        audio.stop()
        route = .phonics(level: level ?? unlockedLevels.last ?? 1)
    }

    func openSound(level: Int, tileID: String) {
        audio.stop()
        route = .sound(level: level, tileID: tileID)
    }

    func openStickers() {
        audio.stop()
        route = .stickers
    }

    func openTrophies() {
        audio.stop()
        route = .trophies
    }

    /// Levels a child can open in Phonics and Storybook.
    var unlockedLevels: [Int] {
        library.books.filter { store.data.isUnlocked($0, in: library) }.map(\.level).sorted()
    }

    func setMusic(_ on: Bool) {
        store.update { $0.settings.musicOn = on }
        music.setEnabled(on)
    }

    /// Music sits lower under reading and phonics screens.
    func musicLevel(for route: Route) -> MusicPlayer.Level {
        switch route {
        case .story, .phonics, .sound, .lesson: return .reading
        default: return .home
        }
    }

    // MARK: Content lookups

    func word(_ text: String) -> WordEntry? { curriculum.word(text, through: level) }

    func phonemeID(_ letter: String) -> String {
        curriculum.grapheme(letter, through: level)?.audio ?? "phoneme_\(letter)"
    }

    func wordID(_ text: String) -> String { word(text)?.audio ?? "word_\(text)" }

    /// The letter's taught sound (never its alphabet name). `highlight` lights the tapped tile while it plays.
    func playPhoneme(_ letter: String, highlight: String? = nil, then completion: (() -> Void)? = nil) {
        audio.play(phonemeID(letter), highlight: highlight, then: completion)
    }

    /// The natural whole-word recording.
    func playWord(_ text: String, highlight: String? = nil, then completion: (() -> Void)? = nil) {
        audio.play(wordID(text), highlight: highlight, then: completion)
    }

    /// "Hear the sounds": the recorded blending model (e.g. blend_s_a_t) when there is one,
    /// otherwise each taught sound in turn, lighting the matching letter (`highlightPrefix` + index).
    func playSounds(of word: String, highlightPrefix: String, then completion: (() -> Void)? = nil) {
        let model = AudioID.blend(word)
        if audio.isAvailable(model) {
            audio.play(model, highlight: highlightPrefix + "all", then: completion)
        } else {
            playLetters(Array(word.map { String($0) }.enumerated()), prefix: highlightPrefix, then: completion)
        }
    }

    private func playLetters(_ letters: [(offset: Int, element: String)], prefix: String, then completion: (() -> Void)?) {
        guard let first = letters.first else { completion?(); return }
        playPhoneme(first.element, highlight: prefix + String(first.offset)) { [weak self] in
            guard let self else { return }
            let rest = Array(letters.dropFirst())
            let expected = self.audio.currentToken
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 350_000_000)
                // A newer tap, a stop, or leaving the screen has taken over: end the sequence.
                guard self.audio.currentToken == expected else { return }
                self.playLetters(rest, prefix: prefix, then: completion)
            }
        }
    }

    func setChime(_ on: Bool) {
        store.update { $0.settings.chime = on }
        audio.effectsEnabled = on
    }

    /// Every Level 1 clip the build can play, in recording-batch order.
    var level1AudioIDs: [String] {
        AudioCatalog.ids(plan: plan, curriculum: curriculum)
            + (library.book(level: 1)?.pages.map(\.narration) ?? [])
            + [MusicPlayer.trackID]
    }
}

/// Lists the clips used by a lesson plan (phonemes, words, blends, prompts, effects).
enum AudioCatalog {
    static func ids(plan: LessonPlan, curriculum: Curriculum) -> [String] {
        var phonemes: [String] = []
        var words: [String] = []
        var blends: [String] = []
        func add(_ id: String, to list: inout [String]) { if !list.contains(id) { list.append(id) } }

        for grapheme in curriculum.level(plan.level)?.graphemes ?? [] {
            if let audio = grapheme.audio { add(audio, to: &phonemes) }
        }
        for page in plan.pages {
            for stage in page.stages {
                switch stage.activity {
                case .pictureTap(let list), .readWords(let list):
                    for w in list { add(curriculum.word(w, through: plan.level)?.audio ?? "word_\(w)", to: &words) }
                case .oralBlend(let list):
                    for w in list {
                        add(curriculum.word(w, through: plan.level)?.audio ?? "word_\(w)", to: &words)
                        add(AudioID.blend(w), to: &blends)
                    }
                case .wordBuilder(_, let build, let change):
                    for w in [build, change] {
                        add(curriculum.word(w, through: plan.level)?.audio ?? "word_\(w)", to: &words)
                        add(AudioID.blend(w), to: &blends)
                    }
                case .lastSound(let rounds, _):
                    for w in rounds { add(curriculum.word(w, through: plan.level)?.audio ?? "word_\(w)", to: &words) }
                default:
                    break
                }
            }
        }
        return phonemes + words + blends + Prompt.allCases.map(\.rawValue) + Effect.allCases.map(\.rawValue)
    }
}
