import Foundation

// MARK: - Content (storybooks.json, phonics_examples.json)

enum PageMode: String, Codable {
    /// Every printed word uses taught patterns or taught tricky words.
    case tryReading
    /// The narrator reads the line; the chips are the independent targets.
    case readTogether
}

/// One character or prop drawn on a story page, feet on the ground line.
struct SceneLayer: Codable, Equatable {
    let asset: String
    /// Horizontal centre and width, as fractions of the scene.
    let x: Double
    let width: Double
    let wobble: Bool
}

struct StoryPage: Codable, Equatable, Identifiable {
    let id: String
    let mode: PageMode
    /// The story line. Nil for draft books that are still being written.
    let line: String?
    let chips: [String]
    let beat: String
    let layers: [SceneLayer]
    let narration: String
    /// Word whose blending model ("Hear sounds") this page offers, if any.
    let hearSounds: String?
    let required: Bool
    let sunset: Bool
}

enum BookStatus: String, Codable {
    case ready
    /// Story beats and targets only; locked as "coming soon".
    case draft
}

struct StoryBook: Codable, Equatable, Identifiable {
    let id: String
    let level: Int
    let title: String
    let status: BookStatus
    let cover: String
    let cast: [String]
    let pages: [StoryPage]

    var requiredPageIDs: Set<String> { Set(pages.filter(\.required).map(\.id)) }
}

struct StoryLibrary: Codable, Equatable {
    let version: Int
    let books: [StoryBook]

    func book(level: Int) -> StoryBook? { books.first { $0.level == level } }
    func book(id: String) -> StoryBook? { books.first { $0.id == id } }

    static func load(from bundle: Bundle = .main) throws -> StoryLibrary {
        guard let url = bundle.url(forResource: "storybooks", withExtension: "json") else {
            throw ContentError.missingFile("storybooks.json")
        }
        return try JSONDecoder().decode(StoryLibrary.self, from: Data(contentsOf: url))
    }
}

struct SoundTile: Codable, Equatable, Identifiable {
    let id: String
    let grapheme: String
    let phoneme: String
    let label: String
    let audio: String
    let examples: [String]

    /// Gesture picture for this sound, when one exists (Level 1: s, a, t, p).
    var actionAsset: String { "action_\(grapheme)" }
}

struct PhonicsLevel: Codable, Equatable {
    let level: Int
    let tiles: [SoundTile]
}

struct PhonicsCatalog: Codable, Equatable {
    let version: Int
    let levels: [PhonicsLevel]

    func tiles(level: Int) -> [SoundTile] { levels.first { $0.level == level }?.tiles ?? [] }

    static func load(from bundle: Bundle = .main) throws -> PhonicsCatalog {
        guard let url = bundle.url(forResource: "phonics_examples", withExtension: "json") else {
            throw ContentError.missingFile("phonics_examples.json")
        }
        return try JSONDecoder().decode(PhonicsCatalog.self, from: Data(contentsOf: url))
    }
}

// MARK: - Trophies and unlocking (pure logic, saved in ProgressData)

/// What finishing a page earned. Both are nil on a reread.
struct PageAwards: Equatable {
    var pageTrophy: String?
    var levelTrophy: Int?
    /// The next level that this finish opened (if its book is ready).
    var unlockedLevel: Int?

    var isEmpty: Bool { pageTrophy == nil && levelTrophy == nil }
}

extension ProgressData {
    func book(_ id: String) -> BookProgress { books[id] ?? BookProgress() }

    /// Levels whose big trophy has been earned.
    var completedLevels: Set<Int> {
        Set(books.compactMap { id, p in p.levelTrophy ? Int(id.replacingOccurrences(of: "book.l", with: "")) : nil })
    }

    /// Level 1 is always open. Level n+1 opens when Level n is complete and its own book is ready.
    func isUnlocked(_ book: StoryBook, in library: StoryLibrary) -> Bool {
        guard book.status == .ready else { return false }
        if book.level == 1 { return true }
        return completedLevels.contains(book.level - 1)
    }

    /// Records the page position (saved when leaving the book or turning pages).
    mutating func setStoryPosition(bookID: String, page: Int) {
        var b = book(bookID)
        b.lastPage = page
        books[bookID] = b
        lastBook = bookID
    }

    /// Finishing a page with Next page or Finish story. Saves awards and the unlock together.
    /// The first finish of a page earns its small trophy; finishing the last required page also
    /// earns the big trophy. Repeats (rereads, double taps, replays) earn nothing.
    mutating func finishPage(_ page: StoryPage, in book: StoryBook, library: StoryLibrary, now: Date = Date()) -> PageAwards {
        var b = self.book(book.id)
        var awards = PageAwards()
        b.completedPages.insert(page.id)
        if b.pageTrophies.insert(page.id).inserted {
            awards.pageTrophy = page.id
        }
        if !b.levelTrophy && book.requiredPageIDs.isSubset(of: b.completedPages) {
            b.levelTrophy = true
            b.completedAt = now
            awards.levelTrophy = book.level
        }
        books[book.id] = b
        lastBook = book.id
        if awards.levelTrophy != nil, let next = library.book(level: book.level + 1), next.status == .ready {
            awards.unlockedLevel = next.level
        }
        return awards
    }

    var pageTrophyCount: Int { books.values.reduce(0) { $0 + $1.pageTrophies.count } }
}

// MARK: - Sticker practice

enum StickerItemKind: String, Codable, Equatable {
    case word, sound
}

/// One practice card: a word or a sound from a completed level.
struct StickerItem: Equatable, Hashable, Identifiable {
    let kind: StickerItemKind
    let level: Int
    /// Word text, or the sound tile's grapheme.
    let value: String
    var id: String { "\(kind.rawValue).l\(level).\(value)" }
}

enum StickerPool {
    /// Items from completed levels only (all of them, or one chosen completed level).
    /// Opening or previewing a book adds nothing.
    static func eligible(kind: StickerItemKind, completed: Set<Int>, filter: Int?,
                         library: StoryLibrary, phonics: PhonicsCatalog) -> [StickerItem] {
        let levels = completed.filter { filter == nil || $0 == filter }.sorted()
        var items: [StickerItem] = []
        for level in levels {
            switch kind {
            case .word:
                let words = library.book(level: level)?.pages.flatMap(\.chips) ?? []
                for w in words where !items.contains(where: { $0.value == w }) {
                    items.append(StickerItem(kind: .word, level: level, value: w))
                }
            case .sound:
                for tile in phonics.tiles(level: level) where !items.contains(where: { $0.value == tile.grapheme && $0.level == level }) {
                    items.append(StickerItem(kind: .sound, level: level, value: tile.grapheme))
                }
            }
        }
        return items
    }

    static func poolKey(kind: StickerItemKind, filter: Int?) -> String {
        "\(kind.rawValue).\(filter.map(String.init) ?? "all")"
    }
}

extension ProgressData {
    /// Draws a card without repeats until the pool is used up, then starts a new round.
    /// `avoid` keeps "Another" from showing the same card twice in a row when a new round begins.
    mutating func drawSticker(from pool: [StickerItem], key: String, avoid: StickerItem? = nil,
                              pick: ([StickerItem]) -> StickerItem? = { $0.randomElement() }) -> StickerItem? {
        guard !pool.isEmpty else { return nil }
        var drawn = Set(stickerDrawn[key] ?? []).intersection(pool.map(\.id))
        var remaining = pool.filter { !drawn.contains($0.id) }
        if remaining.isEmpty {
            drawn = []
            remaining = pool.count > 1 ? pool.filter { $0 != avoid } : pool
        }
        guard let item = pick(remaining) else { return nil }
        drawn.insert(item.id)
        stickerDrawn[key] = Array(drawn).sorted()
        return item
    }
}
