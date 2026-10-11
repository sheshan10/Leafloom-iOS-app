import SwiftUI

/// Filled primary action. Full-width by default, 50 pt tall, with press scale feedback.
struct PrimaryButtonStyle: ButtonStyle {
    var fullWidth = true
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(LeafFont.headline)
            .foregroundStyle(LeafColor.onPrimary)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: LeafSpacing.controlHeight)
            .padding(.horizontal, LeafSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: LeafRadius.md, style: .continuous)
                    .fill(configuration.isPressed ? LeafColor.primaryPressed : LeafColor.primary)
            )
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(.easeOut(duration: LeafMotion.fast), value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

/// Tinted secondary action.
struct SecondaryButtonStyle: ButtonStyle {
    var fullWidth = true
    var tint: Color = LeafColor.primary

    func makeBody(configuration: Configuration) -> some View {
        TintedButtonBody(configuration: configuration, fullWidth: fullWidth, tint: tint)
    }
}

/// Destructive action (delete), styled as a soft red button. Always paired with a confirmation.
struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        TintedButtonBody(configuration: configuration, fullWidth: true, tint: LeafColor.danger)
    }
}

private struct TintedButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let fullWidth: Bool
    let tint: Color
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        configuration.label
            .font(LeafFont.headline)
            .foregroundStyle(tint)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: LeafSpacing.controlHeight)
            .padding(.horizontal, LeafSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: LeafRadius.md, style: .continuous)
                    .fill(tint.opacity(configuration.isPressed ? 0.18 : 0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LeafRadius.md, style: .continuous)
                    .strokeBorder(tint.opacity(0.25), lineWidth: 1)
            )
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(.easeOut(duration: LeafMotion.fast), value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

/// Round icon button used in navigation bars and over hero images. Minimum 44×44 hit area.
struct IconButtonStyle: ButtonStyle {
    var onImage = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(onImage ? Color.white : LeafColor.primary)
            .frame(width: LeafSpacing.touchTarget, height: LeafSpacing.touchTarget)
            .background(
                Circle().fill(onImage ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(LeafColor.primarySoft))
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
            .contentShape(Circle())
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var leafPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var leafSecondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

extension ButtonStyle where Self == DestructiveButtonStyle {
    static var leafDestructive: DestructiveButtonStyle { DestructiveButtonStyle() }
}

extension ButtonStyle where Self == IconButtonStyle {
    static var leafIcon: IconButtonStyle { IconButtonStyle() }
    static var leafIconOnImage: IconButtonStyle { IconButtonStyle(onImage: true) }
}
