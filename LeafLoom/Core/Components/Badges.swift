import SwiftUI

/// Care status shown with icon + text + colour (never colour alone).
struct StatusBadge: View {
    let status: CareStatus

    var body: some View {
        let colors = LeafColor.status(status)
        Label(status.label, systemImage: status.symbol)
            .font(LeafFont.caption)
            .labelStyle(.titleAndIcon)
            .foregroundStyle(colors.foreground)
            .padding(.horizontal, LeafSpacing.xs)
            .padding(.vertical, LeafSpacing.xxs)
            .background(colors.background, in: Capsule())
            .accessibilityLabel("Status: \(status.label)")
    }
}

struct PillBadge: View {
    let text: String
    var systemImage: String?
    var foreground: Color = LeafColor.primary
    var background: Color = LeafColor.primarySoft

    var body: some View {
        HStack(spacing: LeafSpacing.xxs) {
            if let systemImage { Image(systemName: systemImage).accessibilityHidden(true) }
            Text(text)
        }
        .font(LeafFont.caption)
        .foregroundStyle(foreground)
        .padding(.horizontal, LeafSpacing.xs)
        .padding(.vertical, LeafSpacing.xxs)
        .background(background, in: Capsule())
    }
}

/// Marks bundled demonstration records.
struct SampleBadge: View {
    var body: some View {
        PillBadge(text: "Sample", systemImage: "sparkles", foreground: LeafColor.amberText, background: LeafColor.amberSoft)
            .accessibilityLabel("Sample plant")
    }
}

struct CategoryIcon: View {
    let category: PlantCategory
    var size: CGFloat = 20

    var body: some View {
        Image(category.assetName)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct CareCategoryIcon: View {
    let category: CareCategory
    var size: CGFloat = 36

    var body: some View {
        Image(systemName: category.symbol)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(LeafColor.primary)
            .frame(width: size, height: size)
            .background(LeafColor.primarySoft, in: RoundedRectangle(cornerRadius: LeafRadius.md, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// Section title with an optional trailing action ("See all").
struct SectionHeader<Trailing: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder var trailing: () -> Trailing

    init(_ title: String, subtitle: String? = nil, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(LeafFont.title3)
                    .foregroundStyle(LeafColor.text)
                    .accessibilityAddTraits(.isHeader)
                if let subtitle {
                    Text(subtitle)
                        .font(LeafFont.footnote)
                        .foregroundStyle(LeafColor.textSecondary)
                }
            }
            Spacer(minLength: LeafSpacing.xs)
            trailing()
                .font(LeafFont.subheadline.weight(.semibold))
                .foregroundStyle(LeafColor.primary)
        }
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(_ title: String, subtitle: String? = nil) {
        self.init(title, subtitle: subtitle) { EmptyView() }
    }
}

struct FilterChip: View {
    let title: String
    var systemImage: String?
    var assetImage: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LeafSpacing.xxs) {
                if let systemImage { Image(systemName: systemImage).accessibilityHidden(true) }
                if let assetImage {
                    Image(assetImage).renderingMode(.template).resizable().scaledToFit().frame(width: 14, height: 14).accessibilityHidden(true)
                }
                Text(title)
            }
            .font(LeafFont.subheadline.weight(.medium))
            .foregroundStyle(isSelected ? LeafColor.onPrimary : LeafColor.text)
            .padding(.horizontal, LeafSpacing.sm)
            .frame(minHeight: 36)
            .background(isSelected ? LeafColor.primary : LeafColor.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(isSelected ? Color.clear : LeafColor.border, lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Demo-mode notice. Shown wherever a simulated identification result appears.
struct DemoBanner: View {
    var text = "Demo identification — no machine-learning model is installed, so these suggestions are examples, not a real analysis."

    var body: some View {
        HStack(alignment: .top, spacing: LeafSpacing.sm) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(LeafColor.amberText)
                .accessibilityHidden(true)
            Text(text)
                .font(LeafFont.footnote)
                .foregroundStyle(LeafColor.amberText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(LeafSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LeafColor.amberSoft, in: RoundedRectangle(cornerRadius: LeafRadius.md, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("demoBanner")
    }
}
