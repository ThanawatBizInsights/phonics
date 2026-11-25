import XCTest
import UIKit
@testable import PhonicsPond

final class StorybookTests: XCTestCase {
    private var library: StoryLibrary!
    private var phonics: PhonicsCatalog!

    override func setUpWithError() throws {
        library = try StoryLibrary.load()
        phonics = try PhonicsCatalog.load()
    }

    // MARK: Content

    func testTwelveBooksEachWithAtLeastFiveRequiredPages() {
        XCTAssertEqual(library.books.map(\.level).sorted(), Array(1...12))
        for book in library.books {
            XCTAssertGreaterThanOrEqual(book.pages.filter(\.required).count, 5, book.id)
            XCTAssertEqual(Set(book.pages.map(\.id)).count, book.pages.count, "unique page IDs in \(book.id)")
        }
        XCTAssertEqual(library.book(level: 1)?.status, .ready)
        XCTAssertEqual(library.book(level: 1)?.title, "Pat by the Pond")
        XCTAssertTrue(library.books.filter { $0.level > 1 }.allSatisfy { $0.status == .draft })
    }

    func testLevelOneLinesAndChipsMatchTheWireframe() {
        let pages = library.book(level: 1)!.pages
        XCTAssertEqual(pages.map(\.line), ["Pat sat.", "Tap, tap!", "Pat gives the puppy a pat.",
                                           "Pat taps at the edge of the log.", "Pat sat. The puppy stayed beside him."])
        XCTAssertEqual(pages.map(\.chips), [["sat"], ["tap"], ["pat"], ["at", "tap"], ["sat", "pat", "tap"]])
        XCTAssertEqual(pages.map(\.layers.first?.asset), ["pat_sitting_on_log", "pat_tapping_log", "pat_patting",
                                                          "pat_tapping_log", "pat_and_puppy_on_log"])
    }

    func testChipsAndPhonicsExamplesAreReadableAtTheirLevel() throws {
        let curriculum = try Curriculum.load()
        for book in library.books {
            for page in book.pages {
                for chip in page.chips { XCTAssertTrue(curriculum.isReadable(chip, at: book.level), "\(page.id) \(chip)") }
                if page.mode == .tryReading, let line = page.line {
                    for token in EligibilityValidator.tokens(of: line) {
                        XCTAssertTrue(curriculum.isReadable(token, at: book.level), "\(page.id) '\(token)'")
                    }
                }
            }
        }
        for level in phonics.levels {
            for tile in level.tiles {
                for word in tile.examples { XCTAssertTrue(curriculum.isReadable(word, at: level.level), "\(tile.id) \(word)") }
            }
        }
        let l1 = phonics.tiles(level: 1).flatMap(\.examples)
        XCTAssertFalse(l1.contains("sap"))
        XCTAssertFalse(l1.contains("as"))
    }

    func testEveryCoverSceneLayerAndKitAssetIsInTheCatalog() {
        for book in library.books {
            XCTAssertNotNil(UIImage(named: book.cover), book.cover)
            for layer in book.pages.flatMap(\.layers) { XCTAssertNotNil(UIImage(named: layer.asset), layer.asset) }
        }
        XCTAssertEqual(ArtworkNames.missing, [], "kit art missing from Assets.xcassets")
    }

    // MARK: Trophies

    func testFirstFinishAwardsOnePageTrophyAndRereadAwardsNothing() {
        let book = library.book(level: 1)!
        var data = ProgressData()
        let first = data.finishPage(book.pages[0], in: book, library: library)
        XCTAssertEqual(first.pageTrophy, "l1.p1")
        XCTAssertNil(first.levelTrophy)
        let again = data.finishPage(book.pages[0], in: book, library: library)
        XCTAssertTrue(again.isEmpty, "rereading never awards a duplicate")
        XCTAssertEqual(data.book(book.id).pageTrophies.count, 1)
    }

    func testLastRequiredPageAwardsPageAndLevelTrophyTogether() {
        let book = library.book(level: 1)!
        var data = ProgressData()
        for page in book.pages.dropLast() { _ = data.finishPage(page, in: book, library: library) }
        XCTAssertFalse(data.book(book.id).levelTrophy)
        let last = data.finishPage(book.pages.last!, in: book, library: library)
        XCTAssertEqual(last.pageTrophy, "l1.p5")
        XCTAssertEqual(last.levelTrophy, 1)
        XCTAssertNil(last.unlockedLevel, "Level 2 is still a draft, so it stays locked")
        XCTAssertEqual(data.completedLevels, [1])
        let reread = data.finishPage(book.pages.last!, in: book, library: library)
        XCTAssertTrue(reread.isEmpty)
    }

    func testFinishingOutOfOrderStillNeedsEveryRequiredPage() {
        let book = library.book(level: 1)!
        var data = ProgressData()
        _ = data.finishPage(book.pages[4], in: book, library: library)   // last page first
        XCTAssertFalse(data.book(book.id).levelTrophy)
        for page in book.pages.prefix(4) { _ = data.finishPage(page, in: book, library: library) }
        XCTAssertTrue(data.book(book.id).levelTrophy)
    }

    func testSixPageBookUnlocksNextOnlyAfterAllRequiredPages() {
        let lib = Self.testLibrary(firstPages: 6)
        let book = lib.book(level: 1)!
        var data = ProgressData()
        for page in book.pages.prefix(5) { _ = data.finishPage(page, in: book, library: lib) }
        XCTAssertFalse(data.isUnlocked(lib.book(level: 2)!, in: lib))
        let sixth = data.finishPage(book.pages[5], in: book, library: lib)
        XCTAssertEqual(sixth.levelTrophy, 1)
        XCTAssertEqual(sixth.unlockedLevel, 2)
        XCTAssertTrue(data.isUnlocked(lib.book(level: 2)!, in: lib))
    }

    func testLevelOneOpenOnFirstLaunchAndDraftsLocked() {
        let data = ProgressData()
        XCTAssertTrue(data.isUnlocked(library.book(level: 1)!, in: library))
        for level in 2...12 { XCTAssertFalse(data.isUnlocked(library.book(level: level)!, in: library)) }
    }

    // MARK: Opening a book (v1.2: always Page 1)

    func testBooksAlwaysOpenAtPageOne() {
        // New, unfinished (saved position on page 4) and finished books all open at Page 1.
        XCTAssertEqual(AppModel.openingPage(requested: nil, pageCount: 5), 0)
        var data = ProgressData()
        let book = library.book(level: 1)!
        data.setStoryPosition(bookID: book.id, page: 3)
        XCTAssertEqual(AppModel.openingPage(requested: nil, pageCount: book.pages.count), 0, "an old saved position is ignored")
        for page in book.pages { _ = data.finishPage(page, in: book, library: library) }
        XCTAssertEqual(AppModel.openingPage(requested: nil, pageCount: book.pages.count), 0)
        // An explicit page is still clamped to the book.
        XCTAssertEqual(AppModel.openingPage(requested: 9, pageCount: 5), 4)
        XCTAssertEqual(AppModel.openingPage(requested: -2, pageCount: 5), 0)
    }

    func testRereadingAFinishedBookKeepsTrophiesUnlocksAndStickers() {
        let lib = Self.testLibrary(firstPages: 5)
        let book = lib.book(level: 1)!
        var data = ProgressData()
        for page in book.pages { _ = data.finishPage(page, in: book, library: lib) }
        let before = data
        let poolBefore = StickerPool.eligible(kind: .word, completed: data.completedLevels, filter: nil, library: lib, phonics: phonics)

        // Read again from Page 1 to the end.
        data.setStoryPosition(bookID: book.id, page: 0)
        for page in book.pages { XCTAssertTrue(data.finishPage(page, in: book, library: lib).isEmpty, page.id) }

        XCTAssertEqual(data.book(book.id).pageTrophies, before.book(book.id).pageTrophies)
        XCTAssertTrue(data.book(book.id).levelTrophy)
        XCTAssertEqual(data.book(book.id).completedAt, before.book(book.id).completedAt, "the finish date is not overwritten")
        XCTAssertEqual(data.completedLevels, [1])
        XCTAssertTrue(data.isUnlocked(lib.book(level: 2)!, in: lib))
        XCTAssertEqual(StickerPool.eligible(kind: .word, completed: data.completedLevels, filter: nil, library: lib, phonics: phonics),
                       poolBefore)
    }

    // MARK: Phonics (no mouth shapes in the app)

    func testNoScreenRequiresMouthArt() {
        XCTAssertFalse(ArtworkNames.requiredAssets.contains { $0.hasPrefix("mouth_") })
        XCTAssertNotNil(UIImage(named: "mouth_s"), "the original art stays in the catalog for a later update")
        for level in phonics.levels {
            for tile in level.tiles {
                XCTAssertFalse(tile.label.lowercased().contains("mouth"), tile.id)
                XCTAssertFalse(tile.actionAsset.hasPrefix("mouth_"), tile.id)
            }
        }
    }

    func testLevelOneSoundTabsUseIPA() {
        XCTAssertEqual(phonics.tiles(level: 1).map(\.phoneme), ["s", "æ", "t", "p"])
        XCTAssertEqual(phonics.tiles(level: 1).first { $0.grapheme == "p" }?.examples, ["pat", "tap"])
    }

    // MARK: Stickers

    func testStickerPoolIsEmptyUntilALevelIsComplete() {
        var data = ProgressData()
        let book = library.book(level: 1)!
        for page in book.pages.prefix(3) { _ = data.finishPage(page, in: book, library: library) }
        XCTAssertTrue(StickerPool.eligible(kind: .word, completed: data.completedLevels, filter: nil,
                                           library: library, phonics: phonics).isEmpty, "a partly read book adds nothing")
        for page in book.pages { _ = data.finishPage(page, in: book, library: library) }
        let words = StickerPool.eligible(kind: .word, completed: data.completedLevels, filter: nil, library: library, phonics: phonics)
        XCTAssertEqual(Set(words.map(\.value)), ["sat", "tap", "pat", "at"])
        let sounds = StickerPool.eligible(kind: .sound, completed: data.completedLevels, filter: nil, library: library, phonics: phonics)
        XCTAssertEqual(Set(sounds.map(\.value)), ["s", "a", "t", "p"])
    }

    func testStickerFilterWithTwoCompletedBooks() {
        let lib = Self.testLibrary(firstPages: 5)
        let words = StickerPool.eligible(kind: .word, completed: [1, 2], filter: nil, library: lib, phonics: phonics)
        XCTAssertEqual(Set(words.map(\.level)), [1, 2])
        let onlyTwo = StickerPool.eligible(kind: .word, completed: [1, 2], filter: 2, library: lib, phonics: phonics)
        XCTAssertEqual(Set(onlyTwo.map(\.level)), [2])
        let future = StickerPool.eligible(kind: .word, completed: [1], filter: 2, library: lib, phonics: phonics)
        XCTAssertTrue(future.isEmpty, "an uncompleted level is never eligible")
    }

    func testDrawsDoNotRepeatUntilThePoolIsExhausted() {
        var data = ProgressData()
        let pool = ["sat", "tap", "pat", "at"].map { StickerItem(kind: .word, level: 1, value: $0) }
        var seen: [String] = []
        for _ in 0..<4 { seen.append(data.drawSticker(from: pool, key: "word.all")!.value) }
        XCTAssertEqual(Set(seen).count, 4, "no repeats within one round")
        let next = data.drawSticker(from: pool, key: "word.all", avoid: StickerItem(kind: .word, level: 1, value: seen.last!))
        XCTAssertNotEqual(next?.value, seen.last, "a new round does not start with the card just shown")
        XCTAssertNil(data.drawSticker(from: [], key: "empty"))
    }

    // MARK: Saved progress

    func testProgressFromBuildOneStillLoads() throws {
        let old = """
        {"appSeen":{"trace.s":2},"hasLaunchedBefore":true,"lastPage":3,"level":1,
         "observations":[{"date":"2026-11-20T10:00:00Z","id":"7A1D3C1E-1111-4C3B-9B0E-2F6A1B2C3D4E","item":"sat","level":1,"mark":"onOwn","skill":"blending"}],
         "pages":{"1-3":{"completedStages":[0,1],"done":false,"stage":2,"started":true,"step":1}},
         "schema":1,"settings":{"chime":true,"pronoun":"her","thaiHelp":false},
         "stickers":[{"date":"2026-11-20T10:05:00Z","id":"0B1D3C1E-2222-4C3B-9B0E-2F6A1B2C3D4E","kind":"lilypad","level":1,"page":3}]}
        """
        let data = try JSONDecoder.progress.decode(ProgressData.self, from: Data(old.utf8))
        XCTAssertEqual(data.observations.first?.mark, .onOwn)
        XCTAssertEqual(data.stickers.first?.kind.assetName, "sticker_lily")
        XCTAssertEqual(data.progress(page: 3).step, 1)
        XCTAssertTrue(data.settings.musicOn, "music defaults to on for older saves")
        XCTAssertTrue(data.books.isEmpty)
    }

    func testStoryProgressAndMusicSettingSurviveRestart() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("pp-v11-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = ProgressStore(url: url)
        let book = library.book(level: 1)!
        store.update {
            _ = $0.finishPage(book.pages[0], in: book, library: library)
            $0.setStoryPosition(bookID: book.id, page: 2)
            $0.settings.musicOn = false
        }
        let reloaded = ProgressStore(url: url)
        XCTAssertEqual(reloaded.data.book(book.id).lastPage, 2)
        XCTAssertEqual(reloaded.data.book(book.id).pageTrophies, ["l1.p1"])
        XCTAssertEqual(reloaded.data.lastBook, "book.l1")
        XCTAssertFalse(reloaded.data.settings.musicOn)
    }

    // MARK: Helpers

    /// Level 1 with `firstPages` pages, and a ready Level 2 (so unlocking and the two-book pool can be tested).
    static func testLibrary(firstPages: Int) -> StoryLibrary {
        func page(_ level: Int, _ n: Int, _ chip: String) -> StoryPage {
            StoryPage(id: "l\(level).p\(n)", mode: .readTogether, line: "Line \(n).", chips: [chip], beat: "",
                      layers: [], narration: "story_l\(level)_p\(n)", hearSounds: nil, required: true, sunset: false)
        }
        let l1 = StoryBook(id: "book.l1", level: 1, title: "One", status: .ready, cover: "book_cover_01", cast: ["pat"],
                           pages: (1...firstPages).map { page(1, $0, ["sat", "tap", "pat", "at"][($0 - 1) % 4]) })
        let l2 = StoryBook(id: "book.l2", level: 2, title: "Two", status: .ready, cover: "book_cover_02", cast: ["pat", "pip"],
                           pages: (1...5).map { page(2, $0, ["sit", "pin", "tin", "nap", "mad"][$0 - 1]) })
        return StoryLibrary(version: 1, books: [l1, l2])
    }
}

@MainActor
final class MusicPlayerTests: XCTestCase {
    func testMusicTrackIsBundledAndLevelsAreLowUnderReading() {
        let music = MusicPlayer(enabled: true)
        XCTAssertTrue(music.isAvailable, "music_pond_loop is bundled for offline playback")
        XCTAssertLessThan(MusicPlayer.Level.reading.volume, MusicPlayer.Level.home.volume)
        music.duck(true)
        XCTAssertEqual(music.targetVolume, MusicPlayer.duckedVolume)
        music.duck(false)
        XCTAssertEqual(music.targetVolume, MusicPlayer.Level.home.volume)
    }

    func testMusicOffStaysOffOnReturnToForeground() {
        let music = MusicPlayer(enabled: false)
        music.start()        // e.g. scene becomes active
        XCTAssertFalse(music.isPlaying)
        music.setEnabled(true)
        music.pause()        // app goes to background
        XCTAssertFalse(music.isPlaying)
    }
}
