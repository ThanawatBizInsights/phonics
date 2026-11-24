import Foundation
import Observation

/// App-wide state: content, saved progress, audio and the current screen.
@MainActor
@Observable
final class AppModel {
    enum Route: Equatable {
        case home
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
    /// Content problems found at launch (shown in the grown-up area; should be empty).
    let contentIssues: [EligibilityIssue]

    init(store: ProgressStore = ProgressStore(), bundle: Bundle = .main) {
        do {
            curriculum = try Curriculum.load(from: bundle)
            plan = try LessonPlan.load(level: 1, bundle: bundle)
        } catch {
            fatalError("Phonics Pond content failed to load: \(error)")
        }
        self.store = store
        #if DEBUG
        // UI tests start from a clean device state.
        if ProcessInfo.processInfo.arguments.contains("-uiTestReset") { store.reset() }
        #endif
        audio = AudioPlayer(bundle: bundle)
        contentIssues = EligibilityValidator.validate(curriculum) + EligibilityValidator.validate(plan, against: curriculum)
        #if DEBUG
        for issue in contentIssues { print("[content] \(issue)") }
        #endif
        audio.effectsEnabled = store.data.settings.chime
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

    // MARK: Content lookups

    func word(_ text: String) -> WordEntry? { curriculum.word(text, through: level) }

    func phonemeID(_ letter: String) -> String {
        curriculum.grapheme(letter, through: level)?.audio ?? "phoneme_\(letter)"
    }

    func wordID(_ text: String) -> String { word(text)?.audio ?? "word_\(text)" }

    func playPhoneme(_ letter: String, then completion: (() -> Void)? = nil) {
        audio.play(phonemeID(letter), then: completion)
    }

    func playWord(_ text: String, then completion: (() -> Void)? = nil) {
        audio.play(wordID(text), then: completion)
    }

    func setChime(_ on: Bool) {
        store.update { $0.settings.chime = on }
        audio.effectsEnabled = on
    }

    /// Every Level 1 clip the build can play, in recording-batch order.
    var level1AudioIDs: [String] { AudioCatalog.ids(plan: plan, curriculum: curriculum) }
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
