import XCTest
@testable import LeafLoom

final class ReminderFireDateTests: XCTestCase {
    private var calendar: Calendar { Fixtures.calendar.calendar }

    func testFutureDayFiresAtPreferredHour() {
        let fire = ReminderScheduler.fireDate(for: Fixtures.date(2026, 10, 9, 15), hour: 8, now: Fixtures.now, calendar: calendar)
        XCTAssertEqual(fire, Fixtures.date(2026, 10, 9, 8))
    }

    func testTodayBeforePreferredHourFiresAtThatHour() {
        let fire = ReminderScheduler.fireDate(for: Fixtures.date(2026, 10, 7, 9), hour: 18, now: Fixtures.now, calendar: calendar)
        XCTAssertEqual(fire, Fixtures.date(2026, 10, 7, 18))
    }

    func testTodayAfterPreferredHourFiresSoon() {
        let fire = ReminderScheduler.fireDate(for: Fixtures.date(2026, 10, 7, 9), hour: 8, now: Fixtures.now, calendar: calendar)
        XCTAssertEqual(fire, Fixtures.now.addingTimeInterval(60))
    }

    func testOverdueTasksDoNotAlertAgain() {
        XCTAssertNil(ReminderScheduler.fireDate(for: Fixtures.date(2026, 10, 6, 9), hour: 9, now: Fixtures.now, calendar: calendar))
    }
}

final class ImageStoreTests: XCTestCase {
    private var directory: URL!
    private var store: ImageStore!

    override func setUp() {
        super.setUp()
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("ImageStoreTests-\(UUID().uuidString)")
        store = ImageStore(directory: directory)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        super.tearDown()
    }

    func testSaveLoadAndDelete() throws {
        let name = try store.save(Fixtures.jpegData())
        XCTAssertTrue(name.hasSuffix(".jpg"))
        XCTAssertNotNil(store.image(named: name))
        store.delete(name)
        XCTAssertNil(store.image(named: name))
    }

    func testLargeImagesAreDownsampled() throws {
        let name = try store.save(Fixtures.jpegData(width: 3200, height: 2000))
        let saved = try XCTUnwrap(UIImage(contentsOfFile: store.url(for: name).path))
        XCTAssertLessThanOrEqual(max(saved.size.width * saved.scale, saved.size.height * saved.scale), ImageStore.maxPixelSize + 1)
    }

    func testInvalidDataIsRejected() {
        XCTAssertThrowsError(try store.save(Data("not an image".utf8))) { error in
            XCTAssertEqual(error as? ImageStoreError, .invalidImage)
        }
    }

    func testDeleteAllRemovesFiles() throws {
        _ = try store.save(Fixtures.jpegData())
        _ = try store.save(Fixtures.jpegData())
        store.deleteAll()
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path).count, 0)
    }
}
