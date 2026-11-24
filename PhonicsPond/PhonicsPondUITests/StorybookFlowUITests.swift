import XCTest

/// v1.1 end-to-end flows on an iPad simulator (landscape).
/// Narration and phoneme recordings are on hold: every flow must complete without them.
final class StorybookFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        app = XCUIApplication()
    }

    private func launch(reset: Bool = true, extra: [String] = []) {
        app.launchArguments = (reset ? ["-uiTestReset"] : []) + extra
        app.launch()
    }

    private func el(_ id: String) -> XCUIElement { app.descendants(matching: .any)[id].firstMatch }

    private func tapWhenReady(_ id: String, timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) {
        let e = el(id)
        XCTAssertTrue(e.waitForExistence(timeout: timeout), "\(id) exists", file: file, line: line)
        e.tap()
    }

    private func pageChip() -> String { el("story.pageChip").label }

    /// Opens Level 1 from Home and reads every page, accepting each small trophy.
    private func readLevelOne() {
        tapWhenReady("home.storybook")
        tapWhenReady("cover.l1")
        for n in 1...4 {
            XCTAssertTrue(el("story.pageChip").waitForExistence(timeout: 5))
            XCTAssertEqual(pageChip(), "Level 1 · Page \(n) of 5")
            tapWhenReady("story.next")
            tapWhenReady("trophy.nextPage")
        }
        XCTAssertEqual(pageChip(), "Level 1 · Page 5 of 5")
        tapWhenReady("story.finish")
    }

    private func openGrownUps() {
        let lock = app.buttons["Grown-ups"]
        XCTAssertTrue(lock.waitForExistence(timeout: 5))
        lock.press(forDuration: 3.4)
        XCTAssertTrue(app.navigationBars["Grown-ups"].waitForExistence(timeout: 3))
    }

    // MARK: Home

    func testHomeOpensAllThreeDestinations() {
        launch()
        tapWhenReady("home.storybook")
        XCTAssertTrue(el("cover.l1").waitForExistence(timeout: 5), "Storybook shelf")
        app.buttons["Home"].tap()

        tapWhenReady("home.phonics")
        XCTAssertTrue(el("tile.s").waitForExistence(timeout: 5), "Phonics sound picker")
        el("tile.a").tap()
        XCTAssertTrue(app.descendants(matching: .any)["sound a"].waitForExistence(timeout: 5), "sound detail")
        app.buttons["Back to sounds"].firstMatch.tap()
        XCTAssertTrue(el("tile.s").waitForExistence(timeout: 5))
        app.buttons["Home"].tap()

        tapWhenReady("home.stickers")
        XCTAssertTrue(el("stickers.empty").waitForExistence(timeout: 5), "nothing finished yet")
        XCTAssertTrue(el("stickers.trophies").exists)
    }

    func testShelfShowsTwelveCoversOnTwoScreens() {
        launch()
        tapWhenReady("home.storybook")
        for level in 1...6 { XCTAssertTrue(el("cover.l\(level)").waitForExistence(timeout: 5), "cover \(level)") }
        XCTAssertTrue(el("cover.l1").isEnabled, "Level 1 opens on first launch")
        XCTAssertFalse(el("cover.l2").isEnabled, "later levels stay locked")
        XCTAssertTrue(el("cover.l2").label.contains("coming soon"))
        app.buttons["Next shelf"].tap()
        for level in 7...12 { XCTAssertTrue(el("cover.l\(level)").waitForExistence(timeout: 5), "cover \(level)") }
        app.buttons["Previous shelf"].tap()
        XCTAssertTrue(el("cover.l1").waitForExistence(timeout: 5))
    }

    // MARK: Story

    func testReadPagesThenResumeAtSavedPage() {
        launch()
        tapWhenReady("home.storybook")
        tapWhenReady("cover.l1")
        XCTAssertEqual(el("story.line").label, "Pat sat.")
        tapWhenReady("story.next")
        tapWhenReady("trophy.nextPage")
        XCTAssertEqual(el("story.line").label, "Tap, tap!")
        tapWhenReady("story.next")
        tapWhenReady("trophy.nextPage")
        XCTAssertEqual(pageChip(), "Level 1 · Page 3 of 5")

        app.terminate()
        launch(reset: false)
        XCTAssertTrue(app.buttons["home.storybook"].label.contains("Page 3"), "Home shows where the story is")
        tapWhenReady("home.storybook")
        tapWhenReady("shelf.continue")
        XCTAssertEqual(pageChip(), "Level 1 · Page 3 of 5")
        tapWhenReady("story.previous")
        XCTAssertEqual(pageChip(), "Level 1 · Page 2 of 5")
        tapWhenReady("story.next")   // already earned: turns the page, no trophy
        XCTAssertFalse(el("trophy.nextPage").waitForExistence(timeout: 1.5), "a reread awards nothing")
        XCTAssertEqual(pageChip(), "Level 1 · Page 3 of 5")
    }

    func testFinishStoryAwardsSmallThenBigTrophyOnce() {
        launch()
        readLevelOne()
        tapWhenReady("trophy.seeBig")
        XCTAssertTrue(app.staticTexts["Level 1 complete!"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Next level, coming soon"].exists, "Level 2 is still being written")
        XCTAssertFalse(app.buttons["Next level, coming soon"].isEnabled)
        tapWhenReady("trophy.bookshelf")
        XCTAssertTrue(el("cover.l1").label.contains("finished"))

        // Reread the last page: the big trophy shows again, nothing new is earned.
        tapWhenReady("cover.l1")
        XCTAssertEqual(pageChip(), "Level 1 · Page 5 of 5", "reopens at the saved page")
        tapWhenReady("story.finish")
        XCTAssertFalse(el("trophy.seeBig").waitForExistence(timeout: 1.5), "no second small trophy")
        XCTAssertTrue(app.staticTexts["Level 1 trophy"].waitForExistence(timeout: 3))
        tapWhenReady("trophy.bookshelf")
        app.buttons["Home"].tap()
        tapWhenReady("home.stickers")
        tapWhenReady("stickers.trophies")
        XCTAssertEqual(el("trophies.l1").label, "Level 1: 5 of 5 page trophies, big trophy earned")
    }

    func testStoryWorksWithoutRecordings() {
        launch()
        tapWhenReady("home.storybook")
        tapWhenReady("cover.l1")
        let readToMe = app.buttons["Read to me. Audio coming later"]
        XCTAssertTrue(readToMe.waitForExistence(timeout: 5), "narration is on hold")
        XCTAssertFalse(readToMe.isEnabled)
        XCTAssertTrue(app.buttons["Hear sounds. Audio coming later"].exists, "blend recording is on hold")
        XCTAssertTrue(app.buttons["word sat"].isEnabled, "the existing word clip still plays")
        tapWhenReady("story.next")
        XCTAssertTrue(el("trophy.nextPage").waitForExistence(timeout: 3), "pages complete without audio")
    }

    func testRapidTapsNeverDoubleAward() {
        launch()
        tapWhenReady("home.storybook")
        tapWhenReady("cover.l1")
        let next = el("story.next")
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        next.tap(); next.tap(); next.tap()
        tapWhenReady("trophy.nextPage")
        XCTAssertEqual(pageChip(), "Level 1 · Page 2 of 5", "one page per finish")
    }

    // MARK: Stickers

    func testStickerPracticeAfterLevelOneWithFilter() {
        launch()
        readLevelOne()
        tapWhenReady("trophy.seeBig")
        tapWhenReady("trophy.bookshelf")
        app.buttons["Home"].tap()
        tapWhenReady("home.stickers")
        XCTAssertFalse(el("stickers.empty").waitForExistence(timeout: 1.5))

        tapWhenReady("stickers.randomWord")
        let card = el("stickers.card")
        XCTAssertTrue(card.waitForExistence(timeout: 3))
        XCTAssertTrue(["sat", "tap", "pat", "at"].contains(card.label), card.label)
        var seen: Set<String> = [card.label]
        for _ in 0..<3 {
            tapWhenReady("stickers.another")
            seen.insert(el("stickers.card").label)
        }
        XCTAssertEqual(seen.count, 4, "no repeats until all four words are drawn")

        tapWhenReady("stickers.randomSound")
        XCTAssertTrue(["s", "a", "t", "p"].contains(el("stickers.card").label))

        tapWhenReady("stickers.filter")
        app.buttons["Level 1"].firstMatch.tap()
        XCTAssertEqual(el("stickers.filter").label, "Practise from: Level 1")
        tapWhenReady("stickers.randomWord")
        XCTAssertTrue(el("stickers.card").waitForExistence(timeout: 3))
    }

    // MARK: Grown-ups and settings

    func testGrownUpAreaNeedsThreeSecondHold() {
        launch()
        let lock = app.buttons["Grown-ups"]
        XCTAssertTrue(lock.waitForExistence(timeout: 5))
        lock.tap()
        XCTAssertFalse(app.navigationBars["Grown-ups"].waitForExistence(timeout: 1.5), "a quick tap does nothing")
        lock.press(forDuration: 3.4)
        XCTAssertTrue(app.navigationBars["Grown-ups"].waitForExistence(timeout: 3))
    }

    func testMusicToggleIsSavedAcrossLaunches() {
        launch()
        openGrownUps()
        app.staticTexts["Settings"].firstMatch.tap()
        let toggle = app.switches["settings.music"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 3))
        XCTAssertEqual(toggle.value as? String, "1", "music is on by default")
        toggle.switches.firstMatch.tap()
        XCTAssertEqual(toggle.value as? String, "0")

        app.terminate()
        launch(reset: false)
        openGrownUps()
        app.staticTexts["Settings"].firstMatch.tap()
        XCTAssertEqual(app.switches["settings.music"].value as? String, "0", "Music Off is remembered")
    }

    // MARK: Motion

    func testStoryCharactersWobbleUnlessReduceMotion() {
        launch()
        tapWhenReady("home.storybook")
        tapWhenReady("cover.l1")
        let pat = app.buttons["Pat sitting on a log"].firstMatch
        XCTAssertTrue(pat.waitForExistence(timeout: 5))
        XCTAssertEqual(pat.value as? String, "gently moving")
        pat.tap()   // a brief wobble; the page does not change
        XCTAssertEqual(pageChip(), "Level 1 · Page 1 of 5")
    }

    func testReduceMotionKeepsCharactersStill() {
        launch(extra: ["-reduceMotion"])
        tapWhenReady("home.storybook")
        tapWhenReady("cover.l1")
        let pat = app.buttons["Pat sitting on a log"].firstMatch
        XCTAssertTrue(pat.waitForExistence(timeout: 5))
        XCTAssertEqual(pat.value as? String, "still")
    }
}
