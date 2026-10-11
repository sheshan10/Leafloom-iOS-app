import Foundation
import simd

/// Estimates light from horizontal distance to the room's window marker.
///
/// This is a heuristic for a prototype, not a light measurement: it ignores window direction,
/// season, time of day and obstructions. The UI always presents it as an estimate.
enum LightZone {
    /// Upper bounds (metres) for each zone, brightest first.
    static let fullSunLimit: Float = 0.6
    static let brightIndirectLimit: Float = 1.5
    static let mediumLimit: Float = 3.0

    static func estimate(distanceFromWindow distance: Float) -> Sunlight {
        switch max(0, distance) {
        case ..<fullSunLimit: .fullSun
        case ..<brightIndirectLimit: .brightIndirect
        case ..<mediumLimit: .medium
        default: .low
        }
    }

    /// Distance measured on the floor plane, so a plant on a shelf is judged by where it stands.
    static func floorDistance(from window: SIMD3<Float>, to point: SIMD3<Float>) -> Float {
        simd_distance(SIMD2(window.x, window.z), SIMD2(point.x, point.z))
    }

    static func estimate(at point: SIMD3<Float>, window: SIMD3<Float>) -> Sunlight {
        estimate(distanceFromWindow: floorDistance(from: window, to: point))
    }
}

enum LightFit: Equatable, Sendable {
    case good, acceptable, poor

    init(preferred: Sunlight, available: Sunlight) {
        switch abs(preferred.rawValue - available.rawValue) {
        case 0: self = .good
        case 1: self = .acceptable
        default: self = .poor
        }
    }

    var label: String {
        switch self {
        case .good: "Great light match"
        case .acceptable: "Acceptable light"
        case .poor: "Poor light match"
        }
    }

    var symbol: String {
        switch self {
        case .good: "checkmark.circle.fill"
        case .acceptable: "circle.lefthalf.filled"
        case .poor: "exclamationmark.triangle.fill"
        }
    }

    /// Suggests which way to move a plant, or nil when it is already well placed.
    static func advice(preferred: Sunlight, available: Sunlight) -> String? {
        if preferred > available { return "Move closer to the window." }
        if preferred < available { return "Move further from the window." }
        return nil
    }
}
