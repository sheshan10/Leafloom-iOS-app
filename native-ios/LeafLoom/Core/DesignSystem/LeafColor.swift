import SwiftUI

/// Semantic colours. Light/dark values live in Assets.xcassets/Colors (generated from the shared tokens
/// by scripts/generate-native-assets.mjs) and are documented in docs/UI_DESIGN_SYSTEM.md.
enum LeafColor {
    static let background = Color("LeafBackground")
    static let surface = Color("LeafSurface")
    static let surfaceAlt = Color("LeafSurfaceAlt")
    static let surfaceRaised = Color("LeafSurfaceRaised")
    static let text = Color("LeafText")
    static let textSecondary = Color("LeafTextSecondary")
    static let textTertiary = Color("LeafTextTertiary")
    static let border = Color("LeafBorder")
    static let primary = Color("LeafPrimary")
    static let primaryPressed = Color("LeafPrimaryPressed")
    static let onPrimary = Color("LeafOnPrimary")
    static let primarySoft = Color("LeafPrimarySoft")
    static let accent = Color("LeafAccent")
    static let accentSoft = Color("LeafAccentSoft")
    static let amber = Color("LeafAmber")
    static let amberSoft = Color("LeafAmberSoft")
    static let amberText = Color("LeafAmberText")
    static let danger = Color("LeafDanger")
    static let dangerSoft = Color("LeafDangerSoft")
    static let success = Color("LeafSuccess")
    static let successSoft = Color("LeafSuccessSoft")
    static let info = Color("LeafInfo")
    static let infoSoft = Color("LeafInfoSoft")
    static let terracotta = Color("LeafTerracotta")
    static let sage = Color("LeafSage")

    /// Theme-independent brand colours (hero gradients, illustrations).
    static let forest = Color(red: 0x21 / 255, green: 0x4E / 255, blue: 0x3D / 255)
    static let deep = Color(red: 0x17 / 255, green: 0x38 / 255, blue: 0x2E / 255)

    static let chartPalette: [Color] = [primary, accent, amber, terracotta, sage, info, success, textTertiary]

    static func status(_ status: CareStatus) -> (foreground: Color, background: Color) {
        switch status {
        case .overdue: (danger, dangerSoft)
        case .dueToday: (amberText, amberSoft)
        case .upcoming: (info, infoSoft)
        case .completed: (success, successSoft)
        }
    }
}
