import SwiftUI

/// Custom tab bar with a raised central Identify button. Re-selecting a tab pops it to the root.
struct CustomTabBar: View {
    @Environment(AppRouter.self) private var router
    var badges: [AppTab: Int] = [:]
    @Namespace private var selection
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                if tab == .identify {
                    identifyButton
                } else {
                    tabButton(tab)
                }
            }
        }
        .padding(.horizontal, LeafSpacing.xs)
        .padding(.top, LeafSpacing.xs)
        .background(
            LeafColor.surface
                .shadow(color: LeafColor.deep.opacity(0.08), radius: 12, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(alignment: .top) { Divider().opacity(0.5) }
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let selected = router.selectedTab == tab
        let badge = badges[tab] ?? 0
        return Button {
            withAnimation(LeafMotion.animation(LeafMotion.spring, reduceMotion: reduceMotion)) { router.select(tab) }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: selected ? tab.selectedSymbol : tab.symbol)
                    .font(.system(size: 20, weight: selected ? .semibold : .regular))
                    .frame(height: 26)
                    .overlay(alignment: .topTrailing) {
                        if badge > 0 {
                            Text(badge > 9 ? "9+" : "\(badge)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .frame(minWidth: 17, minHeight: 17)
                                .background(LeafColor.terracotta, in: Capsule())
                                .offset(x: 10, y: -4)
                        }
                    }
                Text(tab.title)
                    .font(.caption2.weight(selected ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Capsule()
                    .fill(selected ? LeafColor.primary : Color.clear)
                    .frame(width: 18, height: 3)
                    .matchedGeometryEffect(id: selected ? "indicator" : "none-\(tab.rawValue)", in: selection, isSource: selected)
            }
            .foregroundStyle(selected ? LeafColor.primary : LeafColor.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(badge > 0 ? "\(tab.title), \(badge) need attention" : tab.title)
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
        .accessibilityIdentifier("tab.\(tab.rawValue)")
    }

    private var identifyButton: some View {
        let selected = router.selectedTab == .identify
        return Button {
            router.select(.identify)
        } label: {
            VStack(spacing: 3) {
                Image(systemName: "viewfinder")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(LeafColor.onPrimary)
                    .frame(width: 58, height: 58)
                    .background(
                        Circle().fill(LinearGradient(colors: [LeafColor.accent, LeafColor.primary], startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                    .overlay(Circle().strokeBorder(LeafColor.surface, lineWidth: 4))
                    .shadow(color: LeafColor.primary.opacity(0.35), radius: 10, y: 4)
                    .scaleEffect(selected && !reduceMotion ? 1.05 : 1)
                Text(AppTab.identify.title)
                    .font(.caption2.weight(selected ? .semibold : .medium))
                    .foregroundStyle(selected ? LeafColor.primary : LeafColor.textSecondary)
            }
            .offset(y: -14)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Identify a plant")
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
        .accessibilityIdentifier("tab.identify")
    }
}
