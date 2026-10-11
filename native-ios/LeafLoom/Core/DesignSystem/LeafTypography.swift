import SwiftUI

/// Text styles. All are built on semantic `Font.TextStyle`s so Dynamic Type scales everything.
/// Large titles use the system serif (New York) for an editorial, botanical feel.
enum LeafFont {
    static let largeTitle = Font.system(.largeTitle, design: .serif).weight(.semibold)
    static let title = Font.system(.title, design: .serif).weight(.semibold)
    static let title2 = Font.title2.weight(.semibold)
    static let title3 = Font.title3.weight(.semibold)
    static let headline = Font.headline
    static let body = Font.body
    static let callout = Font.callout
    static let subheadline = Font.subheadline
    static let footnote = Font.footnote
    static let caption = Font.caption.weight(.medium)
    static let eyebrow = Font.caption.weight(.semibold)
    static let metric = Font.system(.title, design: .rounded).weight(.bold)
}

extension View {
    /// Small uppercase label above sections ("YOUR COLLECTION").
    func eyebrowStyle() -> some View {
        font(LeafFont.eyebrow)
            .textCase(.uppercase)
            .tracking(0.8)
            .foregroundStyle(LeafColor.textSecondary)
    }
}
