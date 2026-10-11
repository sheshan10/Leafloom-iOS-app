import SwiftUI

/// Motion tokens. Every animation goes through `LeafMotion.animation(_:reduceMotion:)` so Reduce Motion
/// swaps movement for a short cross-fade (or nothing).
enum LeafMotion {
    static let fast: Double = 0.15
    static let base: Double = 0.25
    static let slow: Double = 0.42

    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.8)
    static let gentle = Animation.easeInOut(duration: base)

    static func animation(_ animation: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? .easeInOut(duration: fast) : animation
    }
}

extension View {
    /// `withAnimation`-style helper that respects Reduce Motion.
    func leafAnimation<V: Equatable>(_ animation: Animation = LeafMotion.spring, value: V) -> some View {
        modifier(ReduceMotionAnimation(animation: animation, value: value))
    }
}

private struct ReduceMotionAnimation<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation
    let value: V

    func body(content: Content) -> some View {
        content.animation(LeafMotion.animation(animation, reduceMotion: reduceMotion), value: value)
    }
}
