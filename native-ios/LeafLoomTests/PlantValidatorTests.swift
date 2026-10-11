import XCTest
@testable import LeafLoom

final class PlantValidatorTests: XCTestCase {
    private func validDraft() -> PlantDraft {
        var d = PlantDraft()
        d.name = "Monty"
        d.category = .foliage
        return d
    }

    func testValidDraftHasNoErrors() {
        XCTAssertTrue(PlantValidator.validate(validDraft(), now: Fixtures.now, calendar: Fixtures.calendar).isEmpty)
    }

    func testNameIsRequiredAfterCollapsingWhitespace() {
        var d = validDraft()
        d.name = "   \n  "
        XCTAssertEqual(PlantValidator.validate(d, now: Fixtures.now)[.name], "Give your plant a name.")
    }

    func testNameLengthLimit() {
        var d = validDraft()
        d.name = String(repeating: "a", count: PlantValidator.nameMax)
        XCTAssertNil(PlantValidator.validate(d, now: Fixtures.now)[.name])
        d.name = String(repeating: "a", count: PlantValidator.nameMax + 1)
        XCTAssertNotNil(PlantValidator.validate(d, now: Fixtures.now)[.name])
    }

    func testCategoryIsRequired() {
        var d = validDraft()
        d.category = nil
        XCTAssertEqual(PlantValidator.validate(d, now: Fixtures.now)[.category], "Choose a category.")
    }

    func testIntervalBounds() {
        var d = validDraft()
        for ok in [1, 7, 365] {
            d.wateringIntervalDays = ok
            XCTAssertNil(PlantValidator.validate(d, now: Fixtures.now)[.wateringInterval], "\(ok) should be valid")
        }
        for bad in [0, -3, 366] {
            d.wateringIntervalDays = bad
            XCTAssertNotNil(PlantValidator.validate(d, now: Fixtures.now)[.wateringInterval], "\(bad) should be rejected")
            d.fertilizingIntervalDays = bad
            XCTAssertNotNil(PlantValidator.validate(d, now: Fixtures.now)[.fertilizingInterval])
        }
    }

    func testAcquisitionDateCannotBeInTheFuture() {
        var d = validDraft()
        d.acquisitionDate = Fixtures.date(2026, 10, 7, 23)
        XCTAssertNil(PlantValidator.validate(d, now: Fixtures.now, calendar: Fixtures.calendar)[.acquisitionDate], "Later today is still today")
        d.acquisitionDate = Fixtures.date(2026, 10, 8, 1)
        XCTAssertNotNil(PlantValidator.validate(d, now: Fixtures.now, calendar: Fixtures.calendar)[.acquisitionDate])
    }

    func testNotesLimit() {
        var d = validDraft()
        d.notes = String(repeating: "x", count: PlantValidator.notesMax + 1)
        XCTAssertNotNil(PlantValidator.validate(d, now: Fixtures.now)[.notes])
    }

    func testTagNormalisation() {
        XCTAssertEqual(PlantValidator.parseTags(" Indoor, indoor ,  ,Rare , rare"), ["indoor", "rare"])
        let many = (1...15).map { "tag\($0)" }
        XCTAssertEqual(PlantValidator.normaliseTags(many).count, PlantValidator.tagMax)
    }

    func testNormalisedCollapsesWhitespace() {
        var d = validDraft()
        d.name = "  Big   Monty  "
        d.location = " Living   room "
        d.notes = "  note \n"
        let n = PlantValidator.normalised(d)
        XCTAssertEqual(n.name, "Big Monty")
        XCTAssertEqual(n.location, "Living room")
        XCTAssertEqual(n.notes, "note")
    }

    func testCareTaskValidation() {
        var t = CareTaskDraft()
        XCTAssertNotNil(PlantValidator.validate(t)[.title])
        t.title = "Water"
        XCTAssertTrue(PlantValidator.validate(t).isEmpty)
        t.recurrenceIntervalDays = 0
        XCTAssertNotNil(PlantValidator.validate(t)[.recurrence])
    }

    func testJournalValidation() {
        var j = JournalDraft(plantID: nil, entryDate: Fixtures.now, notes: "", heightCm: nil)
        var errors = PlantValidator.validate(j, now: Fixtures.now, calendar: Fixtures.calendar)
        XCTAssertNotNil(errors[.plant])
        XCTAssertNotNil(errors[.notes])

        j.plantID = UUID()
        j.notes = "New leaf"
        j.heightCm = 0
        errors = PlantValidator.validate(j, now: Fixtures.now, calendar: Fixtures.calendar)
        XCTAssertEqual(errors[.height], "Height must be greater than 0 and at most 1000 cm.")

        j.heightCm = 1000
        j.entryDate = Fixtures.date(2026, 10, 9)
        errors = PlantValidator.validate(j, now: Fixtures.now, calendar: Fixtures.calendar)
        XCTAssertNil(errors[.height])
        XCTAssertNotNil(errors[.entryDate])
    }
}
