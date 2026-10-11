import CoreData
import UIKit
import XCTest
@testable import LeafLoom

/// Deterministic dates: a Gregorian UTC calendar (weeks start Monday) and a fixed "now" of
/// Wednesday 7 October 2026, 10:00 — the same instant the browser preview's tests use.
enum Fixtures {
    static let calendar: CareCalendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        c.locale = Locale(identifier: "en_GB")
        return CareCalendar(calendar: c)
    }()

    static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 10, _ minute: Int = 0) -> Date {
        calendar.calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    static let now = date(2026, 10, 7, 10)

    static func daysFromNow(_ days: Int, hour: Int = 9) -> Date {
        calendar.at(hour: hour, on: calendar.addingDays(days, to: calendar.startOfDay(now)))
    }

    /// A small solid-colour JPEG for image-store and repository tests.
    static func jpegData(width: Int = 40, height: Int = 30, color: UIColor = .systemGreen) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        let image = renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        return image.jpegData(compressionQuality: 0.9)!
    }

    static func cgImage(width: Int = 32, height: Int = 32, fill: UInt8 = 120) -> CGImage {
        var pixels = [UInt8](repeating: fill, count: width * height * 4)
        let ctx = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        return ctx.makeImage()!
    }
}

/// Records every scheduler call so tests can assert reminder synchronisation.
final class MockReminderScheduler: ReminderScheduling, @unchecked Sendable {
    private let lock = NSLock()
    private var _scheduled: [ReminderRequest] = []
    private var _cancelled: [UUID] = []
    private var _cancelAllCount = 0
    var status: ReminderAuthorization = .authorized

    var scheduled: [ReminderRequest] { lock.withLock { _scheduled } }
    var cancelled: [UUID] { lock.withLock { _cancelled } }
    var cancelAllCount: Int { lock.withLock { _cancelAllCount } }

    func authorizationStatus() async -> ReminderAuthorization { status }
    func requestAuthorization() async -> Bool { status == .authorized }
    func schedule(_ request: ReminderRequest, hour: Int) async { lock.withLock { _scheduled.append(request) } }
    func cancel(taskIDs: [UUID]) { lock.withLock { _cancelled.append(contentsOf: taskIDs) } }
    func cancelAll() { lock.withLock { _cancelAllCount += 1 } }

    /// Scheduling happens in a detached `Task`; wait until the expected number of requests arrived.
    func waitForScheduled(atLeast count: Int, timeout: Duration = .seconds(2)) async {
        let deadline = ContinuousClock.now + timeout
        while scheduled.count < count, ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(10))
        }
    }
}

/// An in-memory Core Data stack with real repositories and a fixed clock.
@MainActor
struct TestStack {
    let persistence: PersistenceController
    let images: ImageStore
    let scheduler: MockReminderScheduler
    let tasks: CareTaskRepository
    let plants: PlantRepository
    let journal: JournalRepository
    let identifications: IdentificationRepository
    let imageDirectory: URL

    var context: NSManagedObjectContext { persistence.viewContext }

    init(now: Date = Fixtures.now, reminderHour: Int? = 9) {
        persistence = PersistenceController(inMemory: true)
        imageDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("LeafLoomTests-\(UUID().uuidString)", isDirectory: true)
        images = ImageStore(directory: imageDirectory)
        scheduler = MockReminderScheduler()
        tasks = CareTaskRepository(context: persistence.viewContext, scheduler: scheduler, calendar: Fixtures.calendar, now: { now }, reminderHour: { reminderHour })
        plants = PlantRepository(context: persistence.viewContext, images: images, tasks: tasks, now: { now })
        journal = JournalRepository(context: persistence.viewContext, images: images, now: { now })
        identifications = IdentificationRepository(context: persistence.viewContext, images: images, now: { now })
    }

    func count(_ entity: String) throws -> Int {
        try context.count(for: NSFetchRequest<NSFetchRequestResult>(entityName: entity))
    }

    func imageFileCount() -> Int {
        (try? FileManager.default.contentsOfDirectory(atPath: imageDirectory.path).count) ?? 0
    }

    @discardableResult
    func makePlant(name: String = "Monty", category: PlantCategory = .foliage, water: Int? = nil, fertilise: Int? = nil, schedule: Bool = false, imageData: Data? = nil) throws -> Plant {
        var draft = PlantDraft()
        draft.name = name
        draft.category = category
        draft.wateringIntervalDays = water
        draft.fertilizingIntervalDays = fertilise
        return try plants.create(draft, imageData: imageData, createCareSchedule: schedule)
    }

    @discardableResult
    func makeTask(for plant: Plant?, title: String = "Water Monty", due: Date = Fixtures.daysFromNow(0), every interval: Int? = nil, category: CareCategory = .watering) throws -> CareTask {
        var draft = CareTaskDraft(plantID: plant?.id)
        draft.title = title
        draft.category = category
        draft.dueDate = due
        draft.recurrenceIntervalDays = interval
        return try tasks.create(draft)
    }
}
