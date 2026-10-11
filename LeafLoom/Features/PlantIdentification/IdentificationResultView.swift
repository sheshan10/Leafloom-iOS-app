import SwiftUI

/// Identification result. Confidence is shown only when a real model supplied it; demo results say so.
struct IdentificationResultView: View {
    let result: IdentificationResult
    let image: UIImage?
    @Binding var selectedLabel: String?
    let onSave: () -> Void
    let onRetry: () -> Void

    private var selected: IdentificationSuggestion? {
        result.suggestions.first { $0.label == selectedLabel } ?? result.top
    }

    /// Below this, the UI encourages comparing alternatives rather than trusting the top label.
    static let lowConfidenceThreshold = 0.4

    var body: some View {
        VStack(alignment: .leading, spacing: LeafSpacing.lg) {
            photo

            if !result.isDemo, let c = result.top?.confidence, c < Self.lowConfidenceThreshold {
                Label("Low confidence. Compare the alternatives below or try a clearer photo.", systemImage: "exclamationmark.triangle")
                    .font(LeafFont.footnote)
                    .foregroundStyle(LeafColor.amberText)
                    .padding(LeafSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LeafColor.amberSoft, in: RoundedRectangle(cornerRadius: LeafRadius.md, style: .continuous))
            }

            if let selected { suggestionCard(selected) }

            if let care = selected?.knowledge { careCard(care) }

            if result.suggestions.count > 1 { alternatives }

            VStack(spacing: LeafSpacing.xs) {
                Button(action: onSave) { Label("Save to My Plants", systemImage: "plus.circle.fill") }
                    .buttonStyle(.leafPrimary)
                    .accessibilityIdentifier("identify.save")
                Button(action: onRetry) { Label("Try another photo", systemImage: "arrow.counterclockwise") }
                    .buttonStyle(.leafSecondary)
            }

            Text("Suggestions can be wrong. Check the name before relying on care advice, especially for pets or edible plants.")
                .font(LeafFont.caption)
                .foregroundStyle(LeafColor.textTertiary)
        }
        .accessibilityIdentifier("identify.result")
    }

    private var photo: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                LeafColor.primarySoft
            }
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: LeafRadius.xl, style: .continuous))
        .overlay(alignment: .bottomLeading) {
            if result.isDemo {
                PillBadge(text: "Demo identification", systemImage: "flask", foreground: .white, background: .black.opacity(0.55))
                    .padding(LeafSpacing.sm)
            }
        }
        .accessibilityHidden(true)
    }

    private func suggestionCard(_ s: IdentificationSuggestion) -> some View {
        VStack(alignment: .leading, spacing: LeafSpacing.xs) {
            Text(s.label == result.top?.label ? "Suggested plant" : "Your choice").eyebrowStyle()
            Text(s.displayName)
                .font(LeafFont.title)
                .foregroundStyle(LeafColor.text)
                .accessibilityAddTraits(.isHeader)
            if let scientific = s.knowledge?.scientificName {
                Text(scientific).font(LeafFont.subheadline).italic().foregroundStyle(LeafColor.textSecondary)
            }
            HStack(spacing: LeafSpacing.xs) {
                if let category = s.knowledge?.category {
                    PillBadge(text: category.label)
                }
                if !result.isDemo, let confidence = s.confidence {
                    PillBadge(
                        text: "\(confidence.formatted(.percent.precision(.fractionLength(0)))) model confidence",
                        systemImage: "gauge.with.dots.needle.33percent",
                        foreground: LeafColor.info,
                        background: LeafColor.infoSoft
                    )
                    .accessibilityLabel("Model confidence \(Int((confidence * 100).rounded())) percent")
                }
            }
            if let summary = s.knowledge?.summary {
                Text(summary).font(LeafFont.body).foregroundStyle(LeafColor.text).fixedSize(horizontal: false, vertical: true)
            } else {
                Text("This label isn’t in LeafLoom’s care library yet, so no care guidance is available.")
                    .font(LeafFont.footnote)
                    .foregroundStyle(LeafColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .leafCard()
    }

    private func careCard(_ k: PlantKnowledge) -> some View {
        VStack(alignment: .leading, spacing: LeafSpacing.sm) {
            SectionHeader("General care", subtitle: "Typical guidance — adjust for your home")
            VStack(alignment: .leading, spacing: LeafSpacing.sm) {
                careLine("drop", "Water about every \(k.wateringIntervalDays) days")
                careLine("leaf.arrow.circlepath", "Fertilise about every \(k.fertilizingIntervalDays) days in the growing season")
                if let light = k.sunlight { careLine("sun.max", light.label) }
                if let humidity = k.humidity { careLine("humidity", "\(humidity.label) humidity") }
                careLine("square.stack.3d.down.right", k.soil)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .leafCard()
        }
    }

    private func careLine(_ symbol: String, _ text: String) -> some View {
        Label {
            Text(text).font(LeafFont.subheadline).foregroundStyle(LeafColor.text)
        } icon: {
            Image(systemName: symbol).foregroundStyle(LeafColor.primary)
        }
    }

    private var alternatives: some View {
        VStack(alignment: .leading, spacing: LeafSpacing.sm) {
            SectionHeader("Other possibilities", subtitle: "Tap to choose instead")
            VStack(spacing: 0) {
                ForEach(result.suggestions) { s in
                    let isSelected = s.label == selected?.label
                    Button { selectedLabel = s.label } label: {
                        HStack(spacing: LeafSpacing.sm) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isSelected ? LeafColor.primary : LeafColor.textTertiary)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(s.displayName).font(LeafFont.headline).foregroundStyle(LeafColor.text)
                                if let sci = s.knowledge?.scientificName {
                                    Text(sci).font(LeafFont.caption).italic().foregroundStyle(LeafColor.textSecondary)
                                }
                            }
                            Spacer()
                            if !result.isDemo, let c = s.confidence {
                                Text(c.formatted(.percent.precision(.fractionLength(0))))
                                    .font(LeafFont.caption)
                                    .foregroundStyle(LeafColor.textSecondary)
                            }
                        }
                        .padding(.vertical, LeafSpacing.xs)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                    if s.id != result.suggestions.last?.id { Divider().padding(.leading, 32) }
                }
            }
            .leafCard(padding: LeafSpacing.sm)
        }
    }
}
