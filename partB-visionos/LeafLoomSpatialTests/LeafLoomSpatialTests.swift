import XCTest
@testable import LeafLoomSpatial

final class LightZoneTests: XCTestCase {
    func testZoneBoundaries() {
        XCTAssertEqual(LightZone.estimate(distanceFromWindow: 0), .fullSun)
        XCTAssertEqual(LightZone.estimate(distanceFromWindow: 0.59), .fullSun)
        XCTAssertEqual(LightZone.estimate(distanceFromWindow: 0.6), .brightIndirect)
        XCTAssertEqual(LightZone.estimate(distanceFromWindow: 1.49), .brightIndirect)
        XCTAssertEqual(LightZone.estimate(distanceFromWindow: 1.5), .medium)
        XCTAssertEqual(LightZone.estimate(distanceFromWindow: 3.0), .low)
        XCTAssertEqual(LightZone.estimate(distanceFromWindow: -1), .fullSun, "Negative distances clamp to zero")
    }

    func testDistanceIgnoresHeight() {
        let window = SIMD3<Float>(0, 0, -2)
        XCTAssertEqual(LightZone.floorDistance(from: window, to: SIMD3(0, 1.5, -2)), 0, accuracy: 0.0001)
        XCTAssertEqual(LightZone.floorDistance(from: window, to: SIMD3(3, 0, 2)), 5, accuracy: 0.0001)
    }

    func testFitAndAdvice() {
        XCTAssertEqual(LightFit(preferred: .medium, available: .medium), .good)
        XCTAssertEqual(LightFit(preferred: .medium, available: .brightIndirect), .acceptable)
        XCTAssertEqual(LightFit(preferred: .low, available: .fullSun), .poor)
        XCTAssertEqual(LightFit.advice(preferred: .fullSun, available: .low), "Move closer to the window.")
        XCTAssertEqual(LightFit.advice(preferred: .low, available: .brightIndirect), "Move further from the window.")
        XCTAssertNil(LightFit.advice(preferred: .medium, available: .medium))
    }
}

final class SampleGardenTests: XCTestCase {
    func testIdsAreStableAndUnique() {
        let first = SampleGarden.plants().map(\.id)
        let second = SampleGarden.plants().map(\.id)
        XCTAssertEqual(first, second)
        XCTAssertEqual(Set(first).count, first.count)
        XCTAssertEqual(first.count, 8)
    }

    func testWateringDue() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let now = Date(timeIntervalSince1970: 1_791_367_200) // 2026-10-07 10:00 UTC
        var plant = SampleGarden.plants(now: now, calendar: calendar)[0]
        plant.wateringIntervalDays = 7
        plant.lastWatered = calendar.date(byAdding: .day, value: -7, to: now)!
        XCTAssertTrue(plant.isWateringDue(now: now, calendar: calendar))
        plant.lastWatered = calendar.date(byAdding: .day, value: -6, to: now)!
        XCTAssertFalse(plant.isWateringDue(now: now, calendar: calendar))
    }

    func testProceduralShapesAreDeterministic() {
        let id = SampleGarden.plants()[0].id
        var a = SeededGenerator(id: id)
        var b = SeededGenerator(id: id)
        XCTAssertEqual((0..<5).map { _ in a.next() }, (0..<5).map { _ in b.next() })
        var other = SeededGenerator(id: SampleGarden.plants()[1].id)
        var c = SeededGenerator(id: id)
        XCTAssertNotEqual(c.next(), other.next())
    }
}

final class GardenStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suite = "LeafLoomSpatialTests"

    override func setUp() {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: suite)
        defaults = UserDefaults(suiteName: suite)
    }

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: suite)
        super.tearDown()
    }

    @MainActor func testDefaultLayoutPlacesEveryPlantOnTheFloor() {
        let store = GardenStore(defaults: defaults)
        XCTAssertEqual(store.placements.count, store.plants.count)
        XCTAssertTrue(store.placements.values.allSatisfy { $0.position.y == 0 && $0.position.z < 0 })
        XCTAssertEqual(store.selectedID, store.plants.first?.id)
    }

    @MainActor func testScaleIsClampedAndYawNormalised() {
        let store = GardenStore(defaults: defaults)
        let id = store.plants[0].id
        store.scale(id, to: 10)
        XCTAssertEqual(store.placement(for: id).scale, GardenStore.scaleRange.upperBound)
        store.scale(id, to: 0.01)
        XCTAssertEqual(store.placement(for: id).scale, GardenStore.scaleRange.lowerBound)
        store.rotate(id, toYaw: 3 * .pi)
        XCTAssertEqual(abs(store.placement(for: id).yaw), .pi, accuracy: 0.0001)
    }

    @MainActor func testMovingKeepsPlantsAboveTheFloorAndChangesLight() {
        let store = GardenStore(defaults: defaults)
        let aloe = store.plants.first { $0.name == "Aloe" }!
        store.move(aloe.id, to: SIMD3(store.windowPosition.x, -1, store.windowPosition.z + 0.2))
        XCTAssertEqual(store.placement(for: aloe.id).position.y, 0)
        XCTAssertEqual(store.light(for: aloe.id), .fullSun)
        XCTAssertEqual(store.fit(for: aloe), .good)
        store.move(aloe.id, to: SIMD3(store.windowPosition.x, 0, store.windowPosition.z + 4))
        XCTAssertEqual(store.fit(for: aloe), .poor)
    }

    @MainActor func testLayoutAndWateringPersistAcrossLaunches() {
        let fixedNow = Date(timeIntervalSince1970: 1_791_367_200)
        let store = GardenStore(defaults: defaults, now: { fixedNow })
        let id = store.plants[2].id
        store.move(id, to: SIMD3(1, 0, -2))
        store.moveWindow(to: SIMD3(-1, 2, -3))
        store.water(id)

        let reopened = GardenStore(defaults: defaults, now: { fixedNow })
        XCTAssertEqual(reopened.placement(for: id).position, SIMD3(1, 0, -2))
        XCTAssertEqual(reopened.windowPosition, SIMD3(-1, 0, -3), "The window marker stays on the floor plane")
        XCTAssertEqual(reopened.plant(id: id)?.lastWatered, fixedNow)
    }

    @MainActor func testUncommittedGestureMovesAreNotSaved() {
        let store = GardenStore(defaults: defaults)
        let id = store.plants[0].id
        let original = store.placement(for: id).position
        store.move(id, to: SIMD3(2, 0, -2), persist: false)
        XCTAssertEqual(GardenStore(defaults: defaults).placement(for: id).position, original)
        store.commitLayout()
        XCTAssertEqual(GardenStore(defaults: defaults).placement(for: id).position, SIMD3(2, 0, -2))
    }

    @MainActor func testResetRestoresDefaults() {
        let store = GardenStore(defaults: defaults)
        let id = store.plants[0].id
        store.move(id, to: SIMD3(2, 0, 2))
        store.moveWindow(to: SIMD3(3, 0, 3))
        store.resetLayout()
        XCTAssertEqual(store.placements, GardenStore.defaultPlacements(for: store.plants))
        XCTAssertEqual(store.windowPosition, GardenStore.defaultWindow)
    }
}
