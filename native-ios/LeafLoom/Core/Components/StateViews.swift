import SwiftUI

/// Friendly empty state with an original illustration and an optional action.
struct EmptyStateView: View {
    let illustration: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: LeafSpacing.md) {
            Image(illustration)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 200, maxHeight: 150)
                .accessibilityHidden(true)
            VStack(spacing: LeafSpacing.xs) {
                Text(title)
                    .font(LeafFont.title3)
                    .foregroundStyle(LeafColor.text)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(LeafFont.subheadline)
                    .foregroundStyle(LeafColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(PrimaryButtonStyle(fullWidth: false))
                    .padding(.top, LeafSpacing.xs)
            }
        }
        .padding(LeafSpacing.lg)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }
}

struct ErrorStateView: View {
    let title: String
    let message: String
    var retry: (() -> Void)?

    var body: some View {
        VStack(spacing: LeafSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(LeafColor.danger)
                .accessibilityHidden(true)
            Text(title).font(LeafFont.title3).foregroundStyle(LeafColor.text).multilineTextAlignment(.center)
            Text(message).font(LeafFont.subheadline).foregroundStyle(LeafColor.textSecondary).multilineTextAlignment(.center)
            if let retry {
                Button("Try again", action: retry).buttonStyle(SecondaryButtonStyle(fullWidth: false))
            }
        }
        .padding(LeafSpacing.lg)
        .frame(maxWidth: .infinity)
    }
}

/// Growing-sprout loading indicator. Uses PhaseAnimator; a plain spinner under Reduce Motion.
struct LoadingView: View {
    var label = "Loading…"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: LeafSpacing.sm) {
            if reduceMotion {
                ProgressView().controlSize(.large).tint(LeafColor.primary)
            } else {
                PhaseAnimator([0.6, 1.0, 0.8]) { scale in
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(LeafColor.accent)
                        .scaleEffect(scale, anchor: .bottom)
                        .rotationEffect(.degrees((scale - 0.8) * 20), anchor: .bottom)
                } animation: { _ in .easeInOut(duration: 0.6) }
            }
            Text(label).font(LeafFont.subheadline).foregroundStyle(LeafColor.textSecondary)
        }
        .padding(LeafSpacing.lg)
        .accessibilityElement(children: .combine)
    }
}

struct StatisticCard: View {
    let title: String
    let value: String
    var systemImage: String
    var tint: Color = LeafColor.primary
    var footnote: String?

    var body: some View {
        VStack(alignment: .leading, spacing: LeafSpacing.xs) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: LeafRadius.sm, style: .continuous))
                .accessibilityHidden(true)
            Text(value)
                .font(LeafFont.metric)
                .foregroundStyle(LeafColor.text)
                .contentTransition(.numericText())
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(title)
                .font(LeafFont.footnote)
                .foregroundStyle(LeafColor.textSecondary)
            if let footnote {
                Text(footnote).font(LeafFont.caption).foregroundStyle(LeafColor.textTertiary)
            }
        }
        .leafCard(padding: LeafSpacing.sm + 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)\(footnote.map { ". \($0)" } ?? "")")
    }
}
