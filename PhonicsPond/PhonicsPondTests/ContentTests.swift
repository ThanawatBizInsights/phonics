import XCTest
@testable import PhonicsPond

/// Content rules: only taught letters and words appear as independent reading targets.
final class ContentTests: XCTestCase {
    private var curriculum: Curriculum!
    private var plan: LessonPlan!

    override func setUpWithError() throws {
        curriculum = try Curriculum.load()
        plan = try LessonPlan.load(level: 1)
    }

    func testCurriculumHasNoEligibilityIssues() {
        XCTAssertEqual(EligibilityValidator.validate(curriculum), [])
    }

    func testLevelOneLessonUsesOnlyTaughtContent() {
        XCTAssertEqual(EligibilityValidator.validate(plan, against: curriculum), [])
    }

    func testLevelOneReadingSetIsExactlySatTapPatAt() {
        let reading = curriculum.level(1)!.words.filter { $0.role == .reading }.map(\.text)
        XCTAssertEqual(reading, ["sat", "tap", "pat", "at"])
        XCTAssertEqual(curriculum.level(1)!.graphemes.map(\.grapheme), ["s", "a", "t", "p"])
    }

    func testAsIsNotReadableInLevelOne() {
        XCTAssertFalse(curriculum.isReadable("as", at: 1), "s in 'as' is /z/")
        XCTAssertFalse(curriculum.isReadable("sap", at: 1), "sap was removed from the Level 1 set")
    }

    func testListeningWordsAreNotReadable() {
        for word in ["sock", "pen", "pot"] {
            XCTAssertEqual(curriculum.word(word, through: 1)?.role, .listening)
            XCTAssertFalse(curriculum.isReadable(word, at: 1))
        }
    }

    func testTrickyAAndIsAreLevelFiveEntriesSeparateFromGraphemeA() {
        let level5 = curriculum.level(5)!
        XCTAssertTrue(level5.tricky.map(\.word).contains("a"))
        XCTAssertTrue(level5.tricky.map(\.word).contains("is"))
        XCTAssertFalse(curriculum.trickyWords(through: 4).contains("a"))
        XCTAssertEqual(curriculum.grapheme("a", through: 1)?.phoneme, "æ")
        XCTAssertTrue(curriculum.isReadable("is", at: 5))
        XCTAssertFalse(curriculum.isReadable("is", at: 4))
    }

    func testBedWaitsForB() {
        XCTAssertFalse(curriculum.isReadable("bed", at: 4), "b is taught in Level 5")
    }

    func testPipArrivesWithShortI() {
        XCTAssertEqual(curriculum.level(1)?.characters, ["Pat"])
        XCTAssertEqual(curriculum.level(2)?.characters, ["Pip"])
        XCTAssertEqual(curriculum.grapheme("i", through: 2)?.phoneme, "ɪ")
    }

    func testEveryPageHasFiveStonesInOrder() {
        XCTAssertEqual(plan.pages.map(\.page), [1, 2, 3, 4, 5])
        for page in plan.pages {
            XCTAssertEqual(page.stages.map(\.stone), Stone.allCases, "page \(page.page)")
            XCTAssertEqual(page.stages.last?.activity, .finish)
        }
    }

    func testValidatorCatchesUntaughtTarget() {
        let bad = LessonPlan(level: 1, pages: [
            LessonPage(page: 1, intro: "x", stages: [LessonStage(stone: .words, activity: .readWords(words: ["pin"]))])
        ])
        XCTAssertFalse(EligibilityValidator.validate(bad, against: curriculum).isEmpty)
    }

    func testAudioCatalogHasNoDuplicatesAndCoversBatches() {
        let ids = AudioCatalog.ids(plan: plan, curriculum: curriculum)
        XCTAssertEqual(ids.count, Set(ids).count, "duplicate clip IDs")
        for id in ["phoneme_s", "phoneme_short_a", "phoneme_t", "phoneme_p",
                   "word_sat", "word_tap", "word_pat", "word_at", "word_sock", "word_pen", "word_pot",
                   "blend_s_a_t", "blend_p_a_t", "effect_soft_chime"] {
            XCTAssertTrue(ids.contains(id), id)
        }
    }
}
