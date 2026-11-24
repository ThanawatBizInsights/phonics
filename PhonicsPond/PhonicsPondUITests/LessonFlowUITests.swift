import XCTest

/// End-to-end flows on the 11-inch iPad simulator (landscape).
/// Recordings may be missing: every flow must still complete, and the debug banner must say so.
final class LessonFlowUITests: XCTestCase {
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

    private func button(beginningWith label: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", label)).firstMatch
    }

    private func waitEnabled(_ element: XCUIElement, timeout: TimeInterval = 10) {
        let predicate = NSPredicate(format: "exists == true AND enabled == true")
        let exp = expectation(for: predicate, evaluatedWith: element)
        wait(for: [exp], timeout: timeout)
    }

    func testHomeToStickerFlow() {
        launch()
        let today = button(beginningWith: "today")
        XCTAssertTrue(today.waitForExistence(timeout: 5), "Home shows the today button")
        today.tap()

        XCTAssertTrue(button(beginningWith: "ears").waitForExistence(timeout: 5), "Five stones are shown")
        for stone in ["sounds", "try", "words", "sticker"] {
            XCTAssertTrue(button(beginningWith: stone).exists, stone)
        }
        button(beginningWith: "ears").tap()

        // Picture tap: hear two pictures, then next
        app.buttons["picture: sock"].tap()
        app.buttons["picture: pen"].tap()
        waitEnabled(app.buttons["next"])
        app.buttons["next"].tap()

        // Sound cards s, a, t, p
        for letter in ["s", "a", "t", "p"] {
            let card = app.buttons["letter \(letter)"]
            XCTAssertTrue(card.waitForExistence(timeout: 5), letter)
            card.tap()
            waitEnabled(app.buttons["next"])
            app.buttons["next"].tap()
        }

        // Optional offline card: skip
        XCTAssertTrue(app.buttons["skip"].waitForExistence(timeout: 5))
        app.buttons["skip"].tap()

        // Oral blending: sat, then pat
        for _ in 0..<2 {
            XCTAssertTrue(app.buttons["hear"].waitForExistence(timeout: 5))
            app.buttons["hear"].tap()
            waitEnabled(app.buttons["hear the word"])
            app.buttons["hear the word"].tap()
            waitEnabled(app.buttons["next"])
            app.buttons["next"].tap()
        }

        // Finish: pick a sticker, then home
        let star = app.buttons["star sticker"]
        XCTAssertTrue(star.waitForExistence(timeout: 5))
        star.tap()
        app.buttons["finishHome"].tap()
        XCTAssertTrue(button(beginningWith: "today").waitForExistence(timeout: 5))
        XCTAssertTrue(button(beginningWith: "today. Level 1, page 2").exists, "today moves on to page 2")

        app.buttons["sticker book"].tap()
        XCTAssertTrue(app.otherElements["star sticker, page 1"].waitForExistence(timeout: 3)
                      || app.staticTexts["page 1"].exists)
    }

    func testMissingRecordingsAreFlaggedButDoNotBlock() {
        launch()
        button(beginningWith: "today").tap()
        button(beginningWith: "sounds").tap()
        // Isolated sounds still need human recordings: tapping a letter shows the debug banner, and the card still works.
        app.buttons["letter s"].tap()
        let banner = app.buttons["pendingAudioBanner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 3))
        XCTAssertTrue(banner.label.contains("phoneme_s"))
        waitEnabled(app.buttons["next"])
    }

    func testGrownUpAreaNeedsThreeSecondHold() {
        launch()
        let lock = app.buttons["Grown-ups"]
        XCTAssertTrue(lock.waitForExistence(timeout: 5))
        lock.tap()
        XCTAssertFalse(app.navigationBars["Grown-ups"].waitForExistence(timeout: 1.5), "a quick tap does nothing")
        lock.press(forDuration: 1.5)
        XCTAssertFalse(app.navigationBars["Grown-ups"].waitForExistence(timeout: 1), "1.5 s is not enough")
        lock.press(forDuration: 3.4)
        XCTAssertTrue(app.navigationBars["Grown-ups"].waitForExistence(timeout: 3), "3 s hold opens the grown-up area")
    }

    func testWordBuilderSatToPatAndResume() {
        launch()
        button(beginningWith: "today").tap()
        button(beginningWith: "page 3").tap()
        button(beginningWith: "try").tap()
        XCTAssertTrue(app.staticTexts["Build sat."].waitForExistence(timeout: 5))

        // Misplaced tile, then send it back
        app.buttons["letter p"].tap()
        XCTAssertTrue(app.buttons["p in the first box"].waitForExistence(timeout: 3))
        app.buttons["p in the first box"].tap()
        XCTAssertTrue(app.buttons["letter p"].waitForExistence(timeout: 3))

        for letter in ["s", "a", "t"] { app.buttons["letter \(letter)"].tap() }
        XCTAssertTrue(app.staticTexts["Say the sounds. Now say the word."].waitForExistence(timeout: 5))
        waitEnabled(app.buttons["hear the word"], timeout: 10)
        app.buttons["hear the word"].tap()
        waitEnabled(app.buttons["next"])
        app.buttons["next"].tap()

        // Change the first sound: s → p
        XCTAssertTrue(app.staticTexts["Change one sound. Make pat."].waitForExistence(timeout: 5))
        app.buttons["s in the first box"].tap()
        app.buttons["letter p"].tap()
        XCTAssertTrue(app.buttons["p in the first box"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["a in the middle box"].exists)
        XCTAssertTrue(app.buttons["t in the last box"].exists)

        // Leave the app and come back: same screen, no restart
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.buttons["p in the first box"].waitForExistence(timeout: 5))

        // Quit and relaunch: Today returns to the saved activity (change step)
        app.terminate()
        launch(reset: false)
        button(beginningWith: "today").tap()
        XCTAssertTrue(app.staticTexts["Change one sound. Make pat."].waitForExistence(timeout: 5),
                      "resumes at the saved Word Builder step")
    }

    func testLastSoundShowsOnlyChoicesUntilAnswered() {
        launch()
        button(beginningWith: "today").tap()
        button(beginningWith: "page 4").tap()
        button(beginningWith: "try").tap()
        XCTAssertTrue(app.buttons["letter t"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["letter p"].exists)
        XCTAssertFalse(app.staticTexts["sat"].exists, "the word is not shown before the child answers")
        app.buttons["letter t"].tap() // first round is "sat"
        waitEnabled(app.buttons["next"])
    }

    func testStopForTodayThenResumeFromHome() {
        launch()
        button(beginningWith: "today").tap()
        button(beginningWith: "page 2").tap()
        button(beginningWith: "try").tap()
        XCTAssertTrue(app.staticTexts["Trace the letter."].waitForExistence(timeout: 5))
        app.buttons["chromeHome"].tap()
        XCTAssertTrue(app.buttons["stop"].waitForExistence(timeout: 3))
        app.buttons["stop"].tap()
        XCTAssertTrue(app.buttons["star sticker"].waitForExistence(timeout: 3), "a sticker is still offered")
        app.buttons["finishHome"].tap()
        button(beginningWith: "today").tap()
        XCTAssertTrue(app.staticTexts["Trace the letter."].waitForExistence(timeout: 5), "today resumes the stopped activity")
    }

    // MARK: - Storytelling motion and feedback

    func testCharactersWobbleAndRespondToTaps() {
        launch()
        let pat = app.buttons["Pat the penguin"].firstMatch
        XCTAssertTrue(pat.waitForExistence(timeout: 5))
        XCTAssertEqual(pat.value as? String, "gently moving")
        pat.tap()   // one brief wobble; nothing else changes
        XCTAssertTrue(button(beginningWith: "today").exists, "navigation stays put")
    }

    func testReduceMotionKeepsCharactersStill() {
        launch(extra: ["-reduceMotion"])
        let pat = app.buttons["Pat the penguin"].firstMatch
        XCTAssertTrue(pat.waitForExistence(timeout: 5))
        XCTAssertEqual(pat.value as? String, "still")
        pat.tap()   // highlight only
        button(beginningWith: "today").tap()
        let lessonPat = app.buttons["Pat the penguin"].firstMatch
        XCTAssertTrue(lessonPat.waitForExistence(timeout: 5))
        XCTAssertEqual(lessonPat.value as? String, "still")
    }

    func testRapidTapsNeverSkipAStep() {
        launch()
        button(beginningWith: "today").tap()
        button(beginningWith: "sounds").tap()
        let s = app.buttons["letter s"]
        XCTAssertTrue(s.waitForExistence(timeout: 5))
        for _ in 0..<5 { s.tap() }          // each tap restarts the sound; no pile-up
        waitEnabled(app.buttons["next"])
        app.buttons["next"].doubleTap()     // a double tap moves one card only
        XCTAssertTrue(app.buttons["letter a"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["letter t"].exists)
    }

    func testReplayAfterInterruptionWithoutAutoplay() {
        launch()
        button(beginningWith: "today").tap()
        button(beginningWith: "page 3").tap()
        button(beginningWith: "try").tap()
        XCTAssertTrue(app.staticTexts["Build sat."].waitForExistence(timeout: 5))
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.staticTexts["Build sat."].waitForExistence(timeout: 5), "same activity after returning")
        let replay = app.buttons["hear again"]
        XCTAssertTrue(replay.exists)
        replay.tap()                       // the child chooses to replay
        XCTAssertTrue(app.staticTexts["Build sat."].exists)
    }

    func testLevelOneReadingFlow() {
        launch()
        button(beginningWith: "today").tap()
        button(beginningWith: "page 5").tap()
        button(beginningWith: "try").tap()
        XCTAssertTrue(app.staticTexts["Read the words."].waitForExistence(timeout: 5))
        for word in ["sat", "tap", "pat", "at"] {
            XCTAssertTrue(app.buttons["hear the sounds in \(word)"].exists, word)
            XCTAssertTrue(app.buttons["hear the word \(word)"].exists, word)
        }
        // Reading comes first: "hear the word" waits for an attempt.
        XCTAssertFalse(app.buttons["hear the word sat"].isEnabled)
        waitEnabled(app.buttons["hear the word sat"], timeout: 8)
        app.buttons["hear the word sat"].tap()
        XCTAssertTrue(app.otherElements["Pat sitting on a log"].waitForExistence(timeout: 3)
                      || app.images["picture for sat"].exists || app.buttons["picture for sat"].exists,
                      "meaning picture appears after the word is heard")
        app.buttons["next"].tap()
        // Grown-up marks
        let lock = app.buttons["Grown-up check"]
        XCTAssertTrue(lock.waitForExistence(timeout: 5))
        lock.press(forDuration: 3.4)
        let mark = app.buttons["sat: On her own"]
        XCTAssertTrue(mark.waitForExistence(timeout: 3))
        mark.tap()
        XCTAssertTrue(mark.isSelected)
    }
}
