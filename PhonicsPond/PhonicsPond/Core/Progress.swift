import Foundation
import Observation

/// Where the child is on one page. Stage is the stone index (0–4); step is the
/// position inside that stone's activity.
struct PageProgress: Codable, Equatable {
    var stage = 0
    var step = 0
    var started = false
    var done = false
    var completedStages: Set<Int> = []
}

enum StickerKind: String, Codable, CaseIterable, Identifiable {
    case penguin, lilypad, star

    var id: String { rawValue }
    /// Raw values stay as saved in earlier builds; the art comes from the v1.1 asset kit.
    var assetName: String {
        switch self {
        case .penguin: return "sticker_pat"
        case .lilypad: return "sticker_lily"
        case .star: return "sticker_star"
        }
    }
    var label: String {
        switch self {
        case .penguin: return "penguin sticker"
        case .lilypad: return "lily pad sticker"
        case .star: return "star sticker"
        }
    }
}

struct EarnedSticker: Codable, Equatable, Identifiable {
    var id = UUID()
    let kind: StickerKind
    let level: Int
    let page: Int
    let date: Date
}

enum Mark: String, Codable, CaseIterable, Identifiable {
    case onOwn, withHelp, notYet

    var id: String { rawValue }

    func label(pronoun: String) -> String {
        switch self {
        case .onOwn: return "On \(pronoun) own"
        case .withHelp: return "With help"
        case .notYet: return "Not yet"
        }
    }

    var thai: String {
        switch self {
        case .onOwn: return "ทำได้เอง"
        case .withHelp: return "ทำได้เมื่อช่วย"
        case .notYet: return "ยังไม่ได้"
        }
    }
}

/// Skills a grown-up observes. The app never scores speech.
enum Skill: String, Codable, CaseIterable, Identifiable {
    case soundRecognition, blending, segmenting, letterFormation, finalSoundClarity

    var id: String { rawValue }

    var title: String {
        switch self {
        case .soundRecognition: return "Sound recognition"
        case .blending: return "Blending (reads the word)"
        case .segmenting: return "Segmenting"
        case .letterFormation: return "Letter formation"
        case .finalSoundClarity: return "Final-sound clarity"
        }
    }

    var thai: String {
        switch self {
        case .soundRecognition: return "รู้จักเสียงของตัวอักษร"
        case .blending: return "ผสมเสียงเป็นคำ"
        case .segmenting: return "แยกคำเป็นเสียง"
        case .letterFormation: return "เขียนตัวอักษร"
        case .finalSoundClarity: return "ออกเสียงท้ายคำชัด"
        }
    }
}

/// A grown-up's dated mark for one skill and item. (Not named `Observation`: that would shadow
/// the Observation framework that `@Observable` expands into.)
struct LearningObservation: Codable, Equatable, Identifiable {
    var id = UUID()
    let level: Int
    let skill: Skill
    let item: String
    let mark: Mark
    let date: Date
}

struct AppSettings: Codable, Equatable {
    var chime = true
    var thaiHelp = false
    var pronoun = "her"
    var pinnedPage: Int?
    /// Background music (Grown-ups › Settings). On by default.
    var musicOn = true

    init() {}

    /// Tolerant decoding: settings saved by earlier builds (without `musicOn`) still load.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        chime = try c.decodeIfPresent(Bool.self, forKey: .chime) ?? true
        thaiHelp = try c.decodeIfPresent(Bool.self, forKey: .thaiHelp) ?? false
        pronoun = try c.decodeIfPresent(String.self, forKey: .pronoun) ?? "her"
        pinnedPage = try c.decodeIfPresent(Int.self, forKey: .pinnedPage)
        musicOn = try c.decodeIfPresent(Bool.self, forKey: .musicOn) ?? true
    }
}

/// Saved state of one storybook. Page and level trophies are sets, so a reread never adds a duplicate.
struct BookProgress: Codable, Equatable {
    var lastPage = 0
    var completedPages: Set<String> = []
    var pageTrophies: Set<String> = []
    var levelTrophy = false
    var completedAt: Date?

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        lastPage = try c.decodeIfPresent(Int.self, forKey: .lastPage) ?? 0
        completedPages = try c.decodeIfPresent(Set<String>.self, forKey: .completedPages) ?? []
        pageTrophies = try c.decodeIfPresent(Set<String>.self, forKey: .pageTrophies) ?? []
        levelTrophy = try c.decodeIfPresent(Bool.self, forKey: .levelTrophy) ?? false
        completedAt = try c.decodeIfPresent(Date.self, forKey: .completedAt)
    }
}

/// Everything saved on the device. Local only: no account, no network.
struct ProgressData: Codable, Equatable {
    var schema = 1
    var level = 1
    var lastPage = 1
    var hasLaunchedBefore = false
    var pages: [String: PageProgress] = [:]
    var stickers: [EarnedSticker] = []
    var observations: [LearningObservation] = []
    /// Touch results the app can check, e.g. "trace.s" or "lastSound.correct".
    var appSeen: [String: Int] = [:]
    var settings = AppSettings()
    /// Storybook progress by book ID (e.g. "book.l1").
    var books: [String: BookProgress] = [:]
    /// The book last opened, for the Home card progress line.
    var lastBook: String?
    /// Sticker practice: items already drawn from each pool, so nothing repeats until the pool is used up.
    var stickerDrawn: [String: [String]] = [:]

    init() {}

    /// Tolerant decoding: progress saved by earlier builds (no storybook fields yet) still loads,
    /// including stickers, positions and grown-up observations.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schema = try c.decodeIfPresent(Int.self, forKey: .schema) ?? 1
        level = try c.decodeIfPresent(Int.self, forKey: .level) ?? 1
        lastPage = try c.decodeIfPresent(Int.self, forKey: .lastPage) ?? 1
        hasLaunchedBefore = try c.decodeIfPresent(Bool.self, forKey: .hasLaunchedBefore) ?? false
        pages = try c.decodeIfPresent([String: PageProgress].self, forKey: .pages) ?? [:]
        stickers = try c.decodeIfPresent([EarnedSticker].self, forKey: .stickers) ?? []
        observations = try c.decodeIfPresent([LearningObservation].self, forKey: .observations) ?? []
        appSeen = try c.decodeIfPresent([String: Int].self, forKey: .appSeen) ?? [:]
        settings = try c.decodeIfPresent(AppSettings.self, forKey: .settings) ?? AppSettings()
        books = try c.decodeIfPresent([String: BookProgress].self, forKey: .books) ?? [:]
        lastBook = try c.decodeIfPresent(String.self, forKey: .lastBook)
        stickerDrawn = try c.decodeIfPresent([String: [String]].self, forKey: .stickerDrawn) ?? [:]
    }

    static func key(level: Int, page: Int) -> String { "\(level)-\(page)" }

    func progress(level: Int = 1, page: Int) -> PageProgress {
        pages[ProgressData.key(level: level, page: page)] ?? PageProgress()
    }

    /// A started, unfinished page to return to.
    func pageInProgress(level: Int = 1, pageCount: Int) -> Int? {
        if progress(level: level, page: lastPage).started && !progress(level: level, page: lastPage).done { return lastPage }
        return (1...pageCount).first { progress(level: level, page: $0).started && !progress(level: level, page: $0).done }
    }

    /// The page the "today" button opens.
    func todayPage(level: Int = 1, pageCount: Int) -> Int {
        if let pinned = settings.pinnedPage, (1...pageCount).contains(pinned) { return pinned }
        if let current = pageInProgress(level: level, pageCount: pageCount) { return current }
        if let next = (1...pageCount).first(where: { !progress(level: level, page: $0).done }) { return next }
        return min(max(lastPage, 1), pageCount)
    }

    func isResuming(level: Int = 1, page: Int) -> Bool {
        let p = progress(level: level, page: page)
        return p.started && !p.done
    }

    func latestMark(level: Int = 1, skill: Skill, item: String) -> LearningObservation? {
        observations.last { $0.level == level && $0.skill == skill && $0.item == item }
    }

    // MARK: Mutations

    mutating func startPage(level: Int = 1, page: Int) {
        var p = progress(level: level, page: page)
        if !p.started || p.done {
            p = PageProgress(stage: 0, step: 0, started: true, done: p.done, completedStages: [])
        }
        pages[ProgressData.key(level: level, page: page)] = p
        lastPage = page
    }

    mutating func setPosition(level: Int = 1, page: Int, stage: Int, step: Int) {
        var p = progress(level: level, page: page)
        p.started = true
        p.stage = stage
        p.step = step
        pages[ProgressData.key(level: level, page: page)] = p
        lastPage = page
    }

    mutating func completeStage(level: Int = 1, page: Int, stage: Int) {
        var p = progress(level: level, page: page)
        p.completedStages.insert(stage)
        pages[ProgressData.key(level: level, page: page)] = p
    }

    /// Called on Session Finish. `completed` is false when the child stopped early:
    /// the position is kept so Home can resume it.
    mutating func finishPage(level: Int = 1, page: Int, completed: Bool) {
        var p = progress(level: level, page: page)
        if completed {
            p.done = true
            p.started = false
            p.stage = 0
            p.step = 0
            if settings.pinnedPage == page { settings.pinnedPage = nil }
        }
        pages[ProgressData.key(level: level, page: page)] = p
    }

    /// "Again": start the page over. A page that was done stays done.
    mutating func restartPage(level: Int = 1, page: Int) {
        var p = progress(level: level, page: page)
        p.started = true
        p.stage = 0
        p.step = 0
        p.completedStages = []
        pages[ProgressData.key(level: level, page: page)] = p
        lastPage = page
    }

    mutating func addSticker(_ kind: StickerKind, level: Int = 1, page: Int, date: Date = Date()) {
        stickers.append(EarnedSticker(kind: kind, level: level, page: page, date: date))
    }

    mutating func mark(_ mark: Mark, skill: Skill, item: String, level: Int = 1, date: Date = Date()) {
        observations.append(LearningObservation(level: level, skill: skill, item: item, mark: mark, date: date))
    }

    mutating func count(_ key: String, by amount: Int = 1) {
        appSeen[key, default: 0] += amount
    }
}

/// Loads and saves `ProgressData` as JSON in Application Support.
@Observable
final class ProgressStore {
    private(set) var data: ProgressData
    private let url: URL

    init(url: URL = ProgressStore.defaultURL) {
        self.url = url
        if let saved = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder.progress.decode(ProgressData.self, from: saved) {
            data = decoded
        } else {
            data = ProgressData()
        }
    }

    static var defaultURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("PhonicsPond", isDirectory: true).appendingPathComponent("progress.json")
    }

    /// Change and save in one step, so nothing is lost if the app is closed.
    func update(_ change: (inout ProgressData) -> Void) {
        change(&data)
        save()
    }

    func save() {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder.progress.encode(data).write(to: url, options: [.atomic])
        } catch {
            #if DEBUG
            print("ProgressStore save failed: \(error)")
            #endif
        }
    }

    func reset() {
        data = ProgressData()
        save()
    }
}

extension JSONEncoder {
    static var progress: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return e
    }
}

extension JSONDecoder {
    static var progress: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}
