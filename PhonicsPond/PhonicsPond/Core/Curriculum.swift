import Foundation

/// Whether a word may be shown as text the child reads, or only heard (with a picture).
enum WordRole: String, Codable {
    case reading
    case listening
}

/// One grapheme–phoneme correspondence, e.g. "a" → /æ/.
struct GPC: Codable, Hashable {
    let grapheme: String
    let phoneme: String
}

struct GraphemeEntry: Codable, Hashable {
    let grapheme: String
    let phoneme: String
    /// Audio ID of the isolated sound, when this level records one.
    let audio: String?
    let label: String?

    var gpc: GPC { GPC(grapheme: grapheme, phoneme: phoneme) }
}

/// A word taught by sight. Kept separate from graphemes, so Level 5's tricky
/// word "a" (said /ə/) never mixes with Level 1's grapheme a (/æ/).
struct TrickyWord: Codable, Hashable {
    let word: String
    let note: String?
}

struct WordEntry: Codable, Hashable {
    let text: String
    let role: WordRole
    let gpcs: [GPC]?
    let audio: String?
    let picture: String?
    let thai: String?
}

struct LevelDefinition: Codable {
    let level: Int
    let title: String
    let playable: Bool
    let characters: [String]
    let focus: String
    let graphemes: [GraphemeEntry]
    let tricky: [TrickyWord]
    let words: [WordEntry]
    let sentences: [String]
}

struct Curriculum: Codable {
    let version: Int
    let accent: String
    let levels: [LevelDefinition]

    func level(_ number: Int) -> LevelDefinition? {
        levels.first { $0.level == number }
    }

    /// Every grapheme–phoneme pair taught at or before `level`.
    func taughtGPCs(through level: Int) -> Set<GPC> {
        Set(levels.filter { $0.level <= level }.flatMap { $0.graphemes.map(\.gpc) })
    }

    func taughtGraphemes(through level: Int) -> Set<String> {
        Set(taughtGPCs(through: level).map(\.grapheme))
    }

    /// Tricky words introduced at or before `level`, lowercased.
    func trickyWords(through level: Int) -> Set<String> {
        Set(levels.filter { $0.level <= level }.flatMap { $0.tricky.map { $0.word.lowercased() } })
    }

    /// The most recent definition of `text` at or before `level`.
    func word(_ text: String, through level: Int) -> WordEntry? {
        for definition in levels.filter({ $0.level <= level }).reversed() {
            if let entry = definition.words.first(where: { $0.text == text }) { return entry }
        }
        return nil
    }

    /// The first-taught entry for a grapheme at or before `level`.
    func grapheme(_ grapheme: String, through level: Int) -> GraphemeEntry? {
        for definition in levels where definition.level <= level {
            if let entry = definition.graphemes.first(where: { $0.grapheme == grapheme }) { return entry }
        }
        return nil
    }

    /// True when `text` can be an independent reading target at `level`.
    func isReadable(_ text: String, at level: Int) -> Bool {
        if trickyWords(through: level).contains(text.lowercased()) { return true }
        guard let entry = word(text, through: level), entry.role == .reading, let gpcs = entry.gpcs else { return false }
        let taught = taughtGPCs(through: level)
        return gpcs.allSatisfy(taught.contains) && gpcs.map(\.grapheme).joined() == text
    }

    static func load(from bundle: Bundle = .main) throws -> Curriculum {
        guard let url = bundle.url(forResource: "curriculum", withExtension: "json") else {
            throw ContentError.missingFile("curriculum.json")
        }
        return try JSONDecoder().decode(Curriculum.self, from: Data(contentsOf: url))
    }
}

enum ContentError: Error, CustomStringConvertible {
    case missingFile(String)

    var description: String {
        switch self {
        case .missingFile(let name): return "Missing bundled content file \(name)"
        }
    }
}

struct EligibilityIssue: Equatable, CustomStringConvertible {
    let level: Int
    let item: String
    let reason: String

    var description: String { "Level \(level) · \(item): \(reason)" }
}

/// Checks that every independent reading target uses only taught correspondences
/// or tricky words that have already been introduced.
enum EligibilityValidator {
    static func validate(_ curriculum: Curriculum) -> [EligibilityIssue] {
        var issues: [EligibilityIssue] = []
        for level in curriculum.levels {
            let taught = curriculum.taughtGPCs(through: level.level)
            let tricky = curriculum.trickyWords(through: level.level)
            for word in level.words where word.role == .reading {
                guard let gpcs = word.gpcs, !gpcs.isEmpty else {
                    issues.append(EligibilityIssue(level: level.level, item: word.text, reason: "reading word has no grapheme breakdown"))
                    continue
                }
                if gpcs.map(\.grapheme).joined() != word.text {
                    issues.append(EligibilityIssue(level: level.level, item: word.text, reason: "graphemes do not spell the word"))
                }
                for gpc in gpcs where !taught.contains(gpc) {
                    issues.append(EligibilityIssue(level: level.level, item: word.text,
                                                   reason: "\(gpc.grapheme) → /\(gpc.phoneme)/ is not taught yet"))
                }
            }
            for sentence in level.sentences {
                for token in tokens(of: sentence) {
                    let readable = tricky.contains(token) || curriculum.isReadable(token, at: level.level)
                    if !readable {
                        issues.append(EligibilityIssue(level: level.level, item: sentence, reason: "\"\(token)\" is not decodable or a taught tricky word"))
                    }
                }
            }
        }
        return issues
    }

    static func validate(_ plan: LessonPlan, against curriculum: Curriculum) -> [EligibilityIssue] {
        var issues: [EligibilityIssue] = []
        let level = plan.level
        let graphemes = curriculum.taughtGraphemes(through: level)
        for page in plan.pages {
            for stage in page.stages {
                let item = "page \(page.page) \(stage.stone.rawValue)"
                for text in stage.activity.readingTargets where !curriculum.isReadable(text, at: level) {
                    issues.append(EligibilityIssue(level: level, item: item, reason: "\"\(text)\" is shown for reading but is not taught"))
                }
                for letter in stage.activity.letterTargets where !graphemes.contains(letter) {
                    issues.append(EligibilityIssue(level: level, item: item, reason: "letter \"\(letter)\" is not taught"))
                }
                for text in stage.activity.listeningWords where curriculum.word(text, through: level) == nil {
                    issues.append(EligibilityIssue(level: level, item: item, reason: "\"\(text)\" is not in the word bank"))
                }
            }
        }
        return issues
    }

    static func tokens(of sentence: String) -> [String] {
        sentence.lowercased()
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { !$0.isEmpty }
    }
}
