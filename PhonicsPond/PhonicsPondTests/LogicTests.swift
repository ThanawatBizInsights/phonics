import CoreGraphics
import XCTest
@testable import PhonicsPond

final class WordBuilderTests: XCTestCase {
    private func tile(_ model: WordBuilderModel, _ letter: String) -> BuilderTile {
        model.trayTiles.first { $0.letter == letter }!
    }

    func testBuildSatByTapping() {
        var m = WordBuilderModel(tray: ["s", "a", "t", "p"], target: "sat")
        XCTAssertEqual(m.place(tile(m, "s")), .correct(slot: 0))
        XCTAssertEqual(m.place(tile(m, "a")), .correct(slot: 1))
        XCTAssertEqual(m.place(tile(m, "t")), .correct(slot: 2))
        XCTAssertTrue(m.isComplete)
        XCTAssertEqual(m.trayTiles.map(\.letter), ["p"])
    }

    func testMisplacedTileCanBeSentBack() {
        var m = WordBuilderModel(tray: ["s", "a", "t", "p"], target: "sat")
        XCTAssertEqual(m.place(tile(m, "p")), .misplaced(slot: 0))
        XCTAssertTrue(m.isMisplaced(0))
        XCTAssertEqual(m.firstProblemSlot, 0)
        XCTAssertEqual(m.remove(from: 0)?.letter, "p")
        XCTAssertTrue(m.trayTiles.map(\.letter).contains("p"))
        XCTAssertEqual(m.misplacedCount, 1)
    }

    func testDragIntoSpecificSlot() {
        var m = WordBuilderModel(tray: ["s", "a", "t", "p"], target: "sat")
        XCTAssertEqual(m.place(tile(m, "t"), in: 2), .correct(slot: 2))
        XCTAssertEqual(m.place(tile(m, "s"), in: 0), .correct(slot: 0))
        XCTAssertFalse(m.isComplete)
        XCTAssertEqual(m.firstProblemSlot, 1)
    }

    func testChangeFirstSoundSatToPat() {
        var m = WordBuilderModel.restored(tray: ["s", "a", "t", "p"], build: "sat", change: "pat", phase: .change)
        XCTAssertEqual(m.builtWord, "sat")
        XCTAssertEqual(m.targetWord, "pat")
        XCTAssertEqual(m.soundsToChange, 1, "only one sound changes")
        XCTAssertEqual(m.firstProblemSlot, 0)
        // Full board: tapping p has no room until s comes out
        XCTAssertEqual(m.place(tile(m, "p")), .noRoom)
        XCTAssertEqual(m.remove(from: 0)?.letter, "s")
        XCTAssertEqual(m.place(tile(m, "p")), .correct(slot: 0))
        XCTAssertTrue(m.isComplete)
        XCTAssertEqual(m.builtWord, "pat")
        XCTAssertEqual(Set(m.trayTiles.map(\.letter)), ["s"])
    }

    func testRestoredPhases() {
        XCTAssertEqual(WordBuilderModel.restored(tray: ["s", "a", "t", "p"], build: "sat", change: "pat", phase: .build).builtWord, "")
        XCTAssertEqual(WordBuilderModel.restored(tray: ["s", "a", "t", "p"], build: "sat", change: "pat", phase: .buildReveal).builtWord, "sat")
        let done = WordBuilderModel.restored(tray: ["s", "a", "t", "p"], build: "sat", change: "pat", phase: .changeReveal)
        XCTAssertEqual(done.builtWord, "pat")
        XCTAssertTrue(done.isComplete)
    }

    func testHelpLadderStopsAtThree() {
        var m = WordBuilderModel(tray: ["s", "a", "t", "p"], target: "sat")
        XCTAssertEqual([m.useHelp(), m.useHelp(), m.useHelp(), m.useHelp()], [1, 2, 3, 3])
        XCTAssertEqual(m.suggestedTile?.letter, "s")
    }

    func testHintPromptsByPosition() {
        XCTAssertEqual(Prompt.tryPosition(0, of: 3), .tryFirstSound)
        XCTAssertEqual(Prompt.tryPosition(1, of: 3), .tryMiddleSound)
        XCTAssertEqual(Prompt.tryPosition(2, of: 3), .tryLastSound)
        XCTAssertEqual(AudioID.blend("sat"), "blend_s_a_t")
    }
}

final class ProgressTests: XCTestCase {
    func testTodayIsFirstPageOnFirstLaunch() {
        XCTAssertEqual(ProgressData().todayPage(pageCount: 5), 1)
    }

    func testResumeReturnsToSavedActivity() {
        var d = ProgressData()
        d.startPage(page: 3)
        d.setPosition(page: 3, stage: 2, step: 1)
        XCTAssertTrue(d.isResuming(page: 3))
        XCTAssertEqual(d.todayPage(pageCount: 5), 3)
        XCTAssertEqual(d.progress(page: 3).stage, 2)
        XCTAssertEqual(d.progress(page: 3).step, 1)
    }

    func testStopEarlyKeepsPositionAndFinishMovesOn() {
        var d = ProgressData()
        d.startPage(page: 1)
        d.setPosition(page: 1, stage: 1, step: 2)
        d.finishPage(page: 1, completed: false)
        XCTAssertTrue(d.isResuming(page: 1))
        XCTAssertEqual(d.progress(page: 1).step, 2)

        d.finishPage(page: 1, completed: true)
        XCTAssertTrue(d.progress(page: 1).done)
        XCTAssertFalse(d.isResuming(page: 1))
        XCTAssertEqual(d.todayPage(pageCount: 5), 2)
    }

    func testAgainKeepsDoneMark() {
        var d = ProgressData()
        d.startPage(page: 2)
        d.finishPage(page: 2, completed: true)
        d.restartPage(page: 2)
        XCTAssertTrue(d.progress(page: 2).done)
        XCTAssertEqual(d.progress(page: 2).stage, 0)
    }

    func testPinnedPageWins() {
        var d = ProgressData()
        d.settings.pinnedPage = 4
        XCTAssertEqual(d.todayPage(pageCount: 5), 4)
    }

    func testStoreRoundTripsStickersAndMarks() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("pp-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = ProgressStore(url: url)
        store.update {
            $0.startPage(page: 3)
            $0.setPosition(page: 3, stage: 2, step: 2)
            $0.addSticker(.lilypad, page: 3)
            $0.mark(.withHelp, skill: .blending, item: "sat")
            $0.mark(.onOwn, skill: .blending, item: "sat")
        }
        let reloaded = ProgressStore(url: url)
        XCTAssertEqual(reloaded.data.progress(page: 3).step, 2)
        XCTAssertEqual(reloaded.data.stickers.map(\.kind), [.lilypad])
        XCTAssertEqual(reloaded.data.latestMark(skill: .blending, item: "sat")?.mark, .onOwn)
        XCTAssertEqual(reloaded.data.observations.count, 2, "every mark is kept with its date")
    }

    func testMarkLabels() {
        XCTAssertEqual(Mark.allCases.map { $0.label(pronoun: "her") }, ["On her own", "With help", "Not yet"])
    }

    func testGrownUpHoldIsThreeSeconds() {
        XCTAssertEqual(GrownUpGate.holdSeconds, 3)
    }
}

final class TraceTests: XCTestCase {
    func testAllLevelOneLettersHavePaths() {
        for letter in ["s", "a", "t", "p"] { XCTAssertNotNil(LetterPath.path(for: letter), letter) }
    }

    func testFollowingTheDotsCompletesTheLetter() {
        for letter in ["s", "a", "t", "p"] {
            var tracker = TraceTracker(path: LetterPath.path(for: letter)!)
            for stroke in tracker.dots {
                XCTAssertTrue(tracker.begin(at: stroke[0]), letter)
                for dot in stroke.dropFirst() { tracker.move(to: dot) }
                tracker.end()
            }
            XCTAssertTrue(tracker.isComplete, letter)
        }
    }

    func testStartingAwayFromTheStartDoesNothing() {
        var tracker = TraceTracker(path: LetterPath.path(for: "t")!)
        XCTAssertFalse(tracker.begin(at: CGPoint(x: 0.95, y: 0.95)))
        tracker.move(to: CGPoint(x: 0.46, y: 0.5))
        XCTAssertEqual(tracker.stroke, 0)
    }
}

@MainActor
final class AudioPlayerTests: XCTestCase {
    func testMissingRecordingStillCompletesAndIsReported() {
        let player = AudioPlayer(bundle: Bundle(for: AudioPlayerTests.self))
        let done = expectation(description: "completion runs without the file")
        player.play("prompt_does_not_exist") { done.fulfill() }
        wait(for: [done], timeout: 2)
        XCTAssertTrue(player.missingIDs.contains("prompt_does_not_exist"))
        XCTAssertEqual(player.lastMissing, "prompt_does_not_exist")
        XCTAssertFalse(player.isPlaying)
    }

    func testNewClipCancelsPreviousCompletion() {
        let player = AudioPlayer(bundle: Bundle(for: AudioPlayerTests.self))
        let first = expectation(description: "first completion must not run")
        first.isInverted = true
        let second = expectation(description: "second completion runs")
        player.play("missing_one") { first.fulfill() }
        player.play("missing_two") { second.fulfill() }
        wait(for: [first, second], timeout: 1.5)
    }

    func testInterruptStopsAndAsksForReplay() {
        let player = AudioPlayer(bundle: Bundle(for: AudioPlayerTests.self))
        let never = expectation(description: "completion dropped after interruption")
        never.isInverted = true
        player.play("missing_clip") { never.fulfill() }
        player.interrupt()
        wait(for: [never], timeout: 1)
        XCTAssertTrue(player.needsReplayCue)
        XCTAssertFalse(player.isPlaying)
    }
}
