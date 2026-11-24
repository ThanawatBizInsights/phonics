import Foundation

/// The five stepping stones every page uses, in order.
enum Stone: String, Codable, CaseIterable {
    case ears, sounds, `try`, words, sticker

    var label: String { rawValue }

    var systemImage: String {
        switch self {
        case .ears: return "ear"
        case .sounds: return "bubble.left.and.text.bubble.right"
        case .`try`: return "hand.point.up.left"
        case .words: return "square.on.square"
        case .sticker: return "star.fill"
        }
    }
}

enum OfflineCardKind: String, Codable {
    case soundHunt
    case tissueGame
}

/// One activity on a page. Decoded from lesson_level1.json by its "type".
enum Activity: Equatable {
    case pictureTap(words: [String])
    case soundCards(letters: [String])
    case reviewSounds(letters: [String])
    case offlineCard(OfflineCardKind)
    case oralBlend(words: [String])
    case trace(letters: [String])
    case wordBuilder(tray: [String], build: String, change: String)
    case lastSound(rounds: [String], choices: [String])
    case readWords(words: [String])
    case grownUpCheck(words: [String], letters: [String])
    case finish

    /// Words shown as text for the child to read independently.
    var readingTargets: [String] {
        switch self {
        case .oralBlend(let words), .readWords(let words), .grownUpCheck(let words, _): return words
        case .wordBuilder(_, let build, let change): return [build, change]
        case .lastSound(let rounds, _): return Array(Set(rounds)).sorted()
        default: return []
        }
    }

    /// Letters shown on tiles, cards or tracing paths.
    var letterTargets: [String] {
        switch self {
        case .soundCards(let letters), .reviewSounds(let letters), .trace(let letters): return letters
        case .wordBuilder(let tray, _, _): return tray
        case .lastSound(_, let choices): return choices
        case .grownUpCheck(_, let letters): return letters
        default: return []
        }
    }

    /// Words that are only heard (pictures allowed, never printed).
    var listeningWords: [String] {
        if case .pictureTap(let words) = self { return words }
        return []
    }

    /// Number of steps, used to save and restore the position inside an activity.
    var stepCount: Int {
        switch self {
        case .pictureTap: return 1
        case .soundCards(let letters), .reviewSounds(let letters): return letters.count
        case .trace(let letters): return letters.count
        case .oralBlend(let words): return words.count
        case .readWords: return 1
        case .wordBuilder: return WordBuilderPhase.allCases.count
        case .lastSound(let rounds, _): return rounds.count
        case .offlineCard, .grownUpCheck, .finish: return 1
        }
    }
}

extension Activity: Decodable {
    private enum Keys: String, CodingKey {
        case type, words, letters, card, tray, build, change, rounds, choices
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        let type = try c.decode(String.self, forKey: .type)
        switch type {
        case "pictureTap": self = .pictureTap(words: try c.decode([String].self, forKey: .words))
        case "soundCards": self = .soundCards(letters: try c.decode([String].self, forKey: .letters))
        case "reviewSounds": self = .reviewSounds(letters: try c.decode([String].self, forKey: .letters))
        case "offlineCard": self = .offlineCard(try c.decode(OfflineCardKind.self, forKey: .card))
        case "oralBlend": self = .oralBlend(words: try c.decode([String].self, forKey: .words))
        case "trace": self = .trace(letters: try c.decode([String].self, forKey: .letters))
        case "wordBuilder":
            self = .wordBuilder(tray: try c.decode([String].self, forKey: .tray),
                                build: try c.decode(String.self, forKey: .build),
                                change: try c.decode(String.self, forKey: .change))
        case "lastSound":
            self = .lastSound(rounds: try c.decode([String].self, forKey: .rounds),
                              choices: try c.decode([String].self, forKey: .choices))
        case "readWords": self = .readWords(words: try c.decode([String].self, forKey: .words))
        case "grownUpCheck":
            self = .grownUpCheck(words: try c.decode([String].self, forKey: .words),
                                 letters: try c.decode([String].self, forKey: .letters))
        case "finish": self = .finish
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: c, debugDescription: "Unknown activity type \(type)")
        }
    }
}

struct LessonStage: Decodable, Equatable {
    let stone: Stone
    let activity: Activity
}

struct LessonPage: Decodable, Equatable {
    let page: Int
    let intro: String
    /// Story characters drawn on this page (ids from `StoryCharacterArt.all`). Defaults to Pat.
    let cast: [String]?
    let stages: [LessonStage]

    init(page: Int, intro: String, cast: [String]? = nil, stages: [LessonStage]) {
        self.page = page
        self.intro = intro
        self.cast = cast
        self.stages = stages
    }

    var castIDs: [String] { cast ?? ["pat"] }
}

struct LessonPlan: Decodable, Equatable {
    let level: Int
    let pages: [LessonPage]

    func page(_ number: Int) -> LessonPage? { pages.first { $0.page == number } }

    static func load(level: Int, bundle: Bundle = .main) throws -> LessonPlan {
        let name = "lesson_level\(level)"
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw ContentError.missingFile("\(name).json")
        }
        return try JSONDecoder().decode(LessonPlan.self, from: Data(contentsOf: url))
    }
}
