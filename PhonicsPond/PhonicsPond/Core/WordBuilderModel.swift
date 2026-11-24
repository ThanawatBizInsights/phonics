import Foundation

/// Saved positions inside the Word Builder. Raw values are stored as the activity step.
enum WordBuilderPhase: Int, CaseIterable, Codable {
    case build = 0        // build the first word (sat)
    case buildReveal = 1  // whole word heard, meaning picture shown
    case change = 2       // change one sound to make the second word (pat)
    case changeReveal = 3 // second word heard, picture shown
}

/// A letter tile. `id` keeps tiles stable when the same letter could appear twice.
struct BuilderTile: Identifiable, Hashable, Codable {
    let id: Int
    let letter: String
}

/// Where a placed tile landed relative to the target word.
enum PlaceOutcome: Equatable {
    case correct(slot: Int)
    case misplaced(slot: Int)
    case noRoom
}

/// Pure model for building a CVC word from tiles, then changing one sound.
/// Contains no UI or audio so it can be unit tested.
struct WordBuilderModel: Equatable {
    let tiles: [BuilderTile]
    private(set) var target: [String]
    private(set) var slots: [BuilderTile?]
    /// Number of help taps used for the current target (0–3).
    private(set) var helpLevel = 0
    private(set) var misplacedCount = 0

    init(tray letters: [String], target word: String) {
        tiles = letters.enumerated().map { BuilderTile(id: $0.offset, letter: $0.element) }
        target = WordBuilderModel.letters(of: word)
        slots = Array(repeating: nil, count: target.count)
    }

    /// Tiles not currently in a slot, in their original tray order.
    var trayTiles: [BuilderTile] {
        let placed = Set(slots.compactMap { $0?.id })
        return tiles.filter { !placed.contains($0.id) }
    }

    var builtWord: String { slots.map { $0?.letter ?? "" }.joined() }
    var isFull: Bool { slots.allSatisfy { $0 != nil } }
    var isComplete: Bool { isFull && slots.map { $0?.letter } == target.map { Optional($0) } }
    var targetWord: String { target.joined() }

    /// The first slot that is empty or holds the wrong tile.
    var firstProblemSlot: Int? {
        slots.indices.first { slots[$0]?.letter != target[$0] }
    }

    func isMisplaced(_ slot: Int) -> Bool {
        guard let tile = slots[slot] else { return false }
        return tile.letter != target[slot]
    }

    /// Tap-to-place: the tile goes to the first empty slot.
    @discardableResult
    mutating func place(_ tile: BuilderTile) -> PlaceOutcome {
        guard let slot = slots.firstIndex(where: { $0 == nil }) else { return .noRoom }
        return place(tile, in: slot)
    }

    /// Drag-to-place: the tile goes to a chosen slot, sending any tile already there back to the tray.
    @discardableResult
    mutating func place(_ tile: BuilderTile, in slot: Int) -> PlaceOutcome {
        guard slots.indices.contains(slot), tiles.contains(tile) else { return .noRoom }
        if let current = slots.firstIndex(where: { $0?.id == tile.id }) { slots[current] = nil }
        slots[slot] = tile
        if tile.letter == target[slot] { return .correct(slot: slot) }
        misplacedCount += 1
        return .misplaced(slot: slot)
    }

    /// Send the tile in `slot` back to the tray.
    @discardableResult
    mutating func remove(from slot: Int) -> BuilderTile? {
        guard slots.indices.contains(slot), let tile = slots[slot] else { return nil }
        slots[slot] = nil
        return tile
    }

    /// Start the "change one sound" step: keep the built tiles, set a new target.
    mutating func retarget(to word: String) {
        let letters = WordBuilderModel.letters(of: word)
        precondition(letters.count == slots.count, "change step must keep the word length")
        target = letters
        helpLevel = 0
    }

    /// Number of slots whose letter differs between the current tiles and the target.
    var soundsToChange: Int {
        slots.indices.filter { slots[$0]?.letter != target[$0] }.count
    }

    mutating func useHelp() -> Int {
        helpLevel = min(helpLevel + 1, 3)
        return helpLevel
    }

    /// The tray tile that belongs in `firstProblemSlot` (used by the third help step).
    var suggestedTile: BuilderTile? {
        guard let slot = firstProblemSlot else { return nil }
        return trayTiles.first { $0.letter == target[slot] }
    }

    static func letters(of word: String) -> [String] { word.map { String($0) } }

    /// Restores the board for a saved phase without replaying anything.
    static func restored(tray: [String], build: String, change: String, phase: WordBuilderPhase) -> WordBuilderModel {
        var model = WordBuilderModel(tray: tray, target: build)
        guard phase != .build else { return model }
        for (index, letter) in letters(of: build).enumerated() {
            if let tile = model.trayTiles.first(where: { $0.letter == letter }) { model.place(tile, in: index) }
        }
        if phase == .change || phase == .changeReveal { model.retarget(to: change) }
        if phase == .changeReveal {
            for (index, letter) in letters(of: change).enumerated() where model.slots[index]?.letter != letter {
                model.remove(from: index)
                if let tile = model.trayTiles.first(where: { $0.letter == letter }) { model.place(tile, in: index) }
            }
        }
        return model
    }
}

enum SlotPosition {
    static func name(_ slot: Int, of count: Int) -> String {
        if slot == 0 { return "first" }
        if slot == count - 1 { return "last" }
        return "middle"
    }
}
