import XCTest

/// End-to-end flows on the simulator. Every launch uses `-uiTesting` (in-memory store, isolated
/// preferences, no permission prompts, instant demo identification) for deterministic state.
final class LeafLoomUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func launch(_ extra: [String] = ["-skipOnboarding"]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"] + extra
        app.launch()
        return app
    }

    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any)[id]
    }

    func testOnboardingCanBeSkipped() {
        let app = launch([])
        let skip = app.buttons["onboarding.skip"]
        XCTAssertTrue(skip.waitForExistence(timeout: 5))
        skip.tap()
        XCTAssertTrue(element(app, "screen.home").waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["tab.plants"].exists)
    }

    func testTabsAreReachable() {
        let app = launch()
        for (tab, screen) in [("tab.plants", "screen.plants"), ("tab.care", "screen.care"), ("tab.insights", "screen.insights"), ("tab.identify", "screen.identify"), ("tab.home", "screen.home")] {
            app.buttons[tab].tap()
            XCTAssertTrue(element(app, screen).waitForExistence(timeout: 5), "\(screen) should appear")
        }
    }

    func testAddPlantShowsValidationThenSaves() {
        let app = launch()
        app.buttons["tab.plants"].tap()
        app.buttons["collection.add"].tap()

        let save = app.buttons["plantForm.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        save.tap()
        XCTAssertTrue(app.staticTexts["Give your plant a name."].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Choose a category."].exists)

        let name = app.textFields["plantForm.name"]
        name.tap()
        name.typeText("Fernando")
        app.buttons["plantForm.category"].tap()
        // The collection's "Fern" filter chip is still in the hierarchy behind the sheet.
        let fern = app.buttons.matching(identifier: "Fern").firstHittable
        XCTAssertNotNil(fern)
        fern?.tap()
        save.tap()

        XCTAssertTrue(element(app, "screen.plantDetails").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Fernando"].firstMatch.exists)
    }

    func testCompletingATaskOffersUndo() {
        let app = launch()
        app.buttons["tab.care"].tap()
        let check = app.buttons.matching(identifier: "taskCheck").firstMatch
        XCTAssertTrue(check.waitForExistence(timeout: 5))
        let label = check.label
        check.tap()

        let undo = app.buttons["Undo"]
        XCTAssertTrue(undo.waitForExistence(timeout: 3))
        undo.tap()
        XCTAssertTrue(app.buttons[label].waitForExistence(timeout: 3), "The task is open again")
    }

    func testDemoIdentificationIsLabelledAndPrefillsForm() {
        let app = launch()
        app.buttons["tab.identify"].tap()
        XCTAssertTrue(element(app, "demoBanner").waitForExistence(timeout: 5))

        app.buttons["identify.sample.ocimum_basilicum"].tap()
        app.buttons["identify.run"].tap()
        XCTAssertTrue(element(app, "identify.result").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Sweet basil"].firstMatch.exists)
        let percentages = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '%'"))
        XCTAssertEqual(percentages.count, 0, "Demo results must never show a confidence")

        let save = app.buttons["identify.save"]
        save.swipeUpIfNeeded(in: app)
        save.tap()
        let name = app.textFields["plantForm.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        XCTAssertEqual(name.value as? String, "Sweet basil")
    }

    func testEmptyStateLaunchArgument() {
        let app = launch(["-skipOnboarding", "-emptyState"])
        app.buttons["tab.plants"].tap()
        XCTAssertTrue(app.staticTexts["No plants yet"].waitForExistence(timeout: 5))
    }

    func testDeletePlantAsksForConfirmation() {
        let app = launch()
        app.buttons["tab.plants"].tap()
        let count = element(app, "collection.count")
        XCTAssertTrue(count.waitForExistence(timeout: 5))
        let before = count.label

        app.descendants(matching: .any).matching(identifier: "plantCard").firstMatch.tap()
        let delete = app.buttons["details.delete"]
        XCTAssertTrue(delete.waitForExistence(timeout: 5))
        delete.swipeUpIfNeeded(in: app)
        delete.tap()
        // The confirmation's button has the same title as the button that opened it.
        _ = app.sheets.firstMatch.waitForExistence(timeout: 3)
        let confirm = app.sheets.buttons["Delete plant"].exists
            ? app.sheets.buttons["Delete plant"]
            : app.buttons.matching(identifier: "Delete plant").firstHittable
        XCTAssertNotNil(confirm)
        confirm?.tap()

        XCTAssertTrue(element(app, "screen.plants").waitForExistence(timeout: 5))
        XCTAssertNotEqual(element(app, "collection.count").label, before)
    }
}

private extension XCUIElementQuery {
    var firstHittable: XCUIElement? {
        allElementsBoundByIndex.first { $0.exists && $0.isHittable }
    }
}

private extension XCUIElement {
    /// Scrolls the main scroll view until the element is hittable (or gives up after a few swipes).
    func swipeUpIfNeeded(in app: XCUIApplication, attempts: Int = 6) {
        var n = 0
        while !isHittable && n < attempts {
            app.swipeUp()
            n += 1
        }
    }
}
