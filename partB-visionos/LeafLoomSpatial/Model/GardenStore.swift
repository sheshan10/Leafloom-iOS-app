import Foundation
import Observation
import simd

/// Where a plant sits in the immersive room. Positions are metres in immersive-space coordinates,
/// where the origin is on the floor at the user's starting position and -z is forward.
struct Placement: Codable, Hashable, Sendable {
    var position: SIMD3<Float>
    var yaw: Float = 0
    var scale: Float = 1
}

/// Single source of truth for the prototype: the plant list, room layout and selection.
/// Layout and watering dates persist in UserDefaults; there is no network or account.
@MainActor
@Observable
final class GardenStore {
    static let scaleRange: ClosedRange<Float> = 0.5...2.0
    static let defaultWindow = SIMD3<Float>(0, 0, -2.5)

    private(set) var plants: [SpatialPlant]
    private(set) var placements: [UUID: Placement]
    private(set) var windowPosition: SIMD3<Float>
    var selectedID: UUID?
    /// Set by the immersive view itself, so it stays correct if the system closes the space.
    var isRoomOpen = false

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let now: () -> Date
    private static let storageKey = "leafloom.spatial.state.v1"

    private struct Snapshot: Codable {
        var lastWatered: [UUID: Date]
        var placements: [UUID: Placement]
        var windowPosition: SIMD3<Float>
    }

    init(defaults: UserDefaults = .standard, now: @escaping () -> Date = { .now }) {
        self.defaults = defaults
        self.now = now
        var plants = SampleGarden.plants(now: now())
        var placements = Self.defaultPlacements(for: plants)
        var window = Self.defaultWindow
        if let data = defaults.data(forKey: Self.storageKey),
           let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) {
            for index in plants.indices {
                if let date = snapshot.lastWatered[plants[index].id] { plants[index].lastWatered = date }
            }
            placements.merge(snapshot.placements.filter { key, _ in plants.contains { $0.id == key } }) { _, saved in saved }
            window = snapshot.windowPosition
        }
        self.plants = plants
        self.placements = placements
        self.windowPosition = window
        self.selectedID = plants.first?.id
    }

    /// A gentle arc in front of the user, two rows deep, at floor level.
    static func defaultPlacements(for plants: [SpatialPlant]) -> [UUID: Placement] {
        var result: [UUID: Placement] = [:]
        let perRow = 4
        for (index, plant) in plants.enumerated() {
            let row = index / perRow
            let column = index % perRow
            let x = (Float(column) - Float(perRow - 1) / 2) * 0.7
            let z = -1.2 - Float(row) * 0.8
            result[plant.id] = Placement(position: SIMD3(x, 0, z))
        }
        return result
    }

    var selectedPlant: SpatialPlant? { plants.first { $0.id == selectedID } }

    func plant(id: UUID) -> SpatialPlant? { plants.first { $0.id == id } }

    func placement(for id: UUID) -> Placement {
        placements[id] ?? Placement(position: SIMD3(0, 0, -1.5))
    }

    func light(for id: UUID) -> Sunlight {
        LightZone.estimate(at: placement(for: id).position, window: windowPosition)
    }

    func fit(for plant: SpatialPlant) -> LightFit {
        LightFit(preferred: plant.sunlight, available: light(for: plant.id))
    }

    var plantsNeedingWater: [SpatialPlant] {
        plants.filter { $0.isWateringDue(now: now()) }
    }

    // MARK: Mutations

    /// Gestures update live with `persist: false` and write once when they end.
    func move(_ id: UUID, to position: SIMD3<Float>, persist: Bool = true) {
        guard plant(id: id) != nil else { return }
        var placement = placement(for: id)
        placement.position = SIMD3(position.x, max(0, position.y), position.z)
        placements[id] = placement
        if persist { save() }
    }

    func rotate(_ id: UUID, toYaw yaw: Float, persist: Bool = true) {
        guard plant(id: id) != nil else { return }
        placements[id, default: placement(for: id)].yaw = Self.normalised(yaw)
        if persist { save() }
    }

    func scale(_ id: UUID, to scale: Float, persist: Bool = true) {
        guard plant(id: id) != nil else { return }
        placements[id, default: placement(for: id)].scale = Self.clampedScale(scale)
        if persist { save() }
    }

    func moveWindow(to position: SIMD3<Float>, persist: Bool = true) {
        windowPosition = SIMD3(position.x, 0, position.z)
        if persist { save() }
    }

    func commitLayout() { save() }

    func water(_ id: UUID) {
        guard let index = plants.firstIndex(where: { $0.id == id }) else { return }
        plants[index].lastWatered = now()
        save()
    }

    func resetLayout() {
        placements = Self.defaultPlacements(for: plants)
        windowPosition = Self.defaultWindow
        save()
    }

    static func clampedScale(_ value: Float) -> Float {
        min(max(value, scaleRange.lowerBound), scaleRange.upperBound)
    }

    /// Keeps yaw in -π...π so stored values do not grow without bound.
    static func normalised(_ yaw: Float) -> Float {
        atan2(sin(yaw), cos(yaw))
    }

    private func save() {
        let snapshot = Snapshot(
            lastWatered: Dictionary(uniqueKeysWithValues: plants.map { ($0.id, $0.lastWatered) }),
            placements: placements,
            windowPosition: windowPosition
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}
