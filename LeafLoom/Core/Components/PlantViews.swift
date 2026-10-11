import SwiftUI
import UIKit

/// Plant photo from the image store, the bundled sample asset, or a category placeholder.
struct PlantThumbnail: View {
    @Environment(AppEnvironment.self) private var env
    let imageFilename: String?
    let sampleAssetName: String?
    let category: PlantCategory
    var cornerRadius: CGFloat = LeafRadius.md
    var maxPixelSize: CGFloat = 600

    init(plant: Plant, cornerRadius: CGFloat = LeafRadius.md, maxPixelSize: CGFloat = 600) {
        imageFilename = plant.imageFilename
        sampleAssetName = plant.sampleAssetName
        category = plant.category
        self.cornerRadius = cornerRadius
        self.maxPixelSize = maxPixelSize
    }

    init(imageFilename: String?, sampleAssetName: String? = nil, category: PlantCategory, cornerRadius: CGFloat = LeafRadius.md) {
        self.imageFilename = imageFilename
        self.sampleAssetName = sampleAssetName
        self.category = category
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        Color.clear
            .overlay {
                if let image = loadImage() {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    ZStack {
                        LinearGradient(colors: [LeafColor.primarySoft, LeafColor.accentSoft], startPoint: .topLeading, endPoint: .bottomTrailing)
                        CategoryIcon(category: category, size: 34)
                            .foregroundStyle(LeafColor.primary.opacity(0.7))
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .accessibilityHidden(true)
    }

    private func loadImage() -> UIImage? {
        if let imageFilename, let image = env.images.image(named: imageFilename, maxPixelSize: maxPixelSize) { return image }
        if let sampleAssetName { return UIImage(named: sampleAssetName) }
        return nil
    }
}

struct FavoriteButton: View {
    let isFavorite: Bool
    var onImage = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .foregroundStyle(isFavorite ? LeafColor.terracotta : (onImage ? Color.white : LeafColor.textSecondary))
                .symbolEffect(.bounce, value: isFavorite)
        }
        .buttonStyle(IconButtonStyle(onImage: onImage))
        .accessibilityLabel(isFavorite ? "Remove from favourites" : "Add to favourites")
        .sensoryFeedback(.selection, trigger: isFavorite)
    }
}

func nextCareSummary(_ plant: Plant, now: Date = .now) -> String {
    guard let next = plant.nextOpenTask else { return "No care scheduled" }
    let status = CareStatusEvaluator.status(of: next, now: now)
    switch status {
    case .overdue: return "\(next.category.label) overdue"
    case .dueToday: return "\(next.category.label) today"
    default: return "\(next.category.label) \(RelativeDayFormatter.string(for: next.dueDate, now: now).lowercased())"
    }
}

struct PlantCardView: View {
    @ObservedObject var plant: Plant
    let onFavorite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PlantThumbnail(plant: plant, cornerRadius: 0)
                .frame(height: 150)
                .overlay(alignment: .topTrailing) {
                    FavoriteButton(isFavorite: plant.isFavorite, onImage: true, action: onFavorite)
                        .padding(LeafSpacing.xs)
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(plant.name)
                    .font(LeafFont.headline)
                    .foregroundStyle(LeafColor.text)
                    .lineLimit(1)
                Text(plant.commonName ?? plant.category.label)
                    .font(LeafFont.footnote)
                    .foregroundStyle(LeafColor.textSecondary)
                    .lineLimit(1)
                Label(nextCareSummary(plant), systemImage: "drop")
                    .font(LeafFont.caption)
                    .foregroundStyle(LeafColor.primary)
                    .lineLimit(1)
                    .padding(.top, 4)
            }
            .padding(LeafSpacing.sm)
        }
        .background(LeafColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: LeafRadius.lg, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: LeafRadius.lg, style: .continuous).strokeBorder(LeafColor.border, lineWidth: 0.5))
        .shadow(color: LeafColor.deep.opacity(0.06), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(plant.name), \(plant.category.label). \(nextCareSummary(plant))\(plant.isFavorite ? ". Favourite" : "")")
        .accessibilityAction(named: plant.isFavorite ? "Remove from favourites" : "Add to favourites", onFavorite)
    }
}

struct PlantRowView: View {
    @ObservedObject var plant: Plant
    var showsChevron = true

    var body: some View {
        HStack(spacing: LeafSpacing.sm) {
            PlantThumbnail(plant: plant, maxPixelSize: 200)
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(plant.name).font(LeafFont.headline).foregroundStyle(LeafColor.text)
                    if plant.isFavorite {
                        Image(systemName: "heart.fill").font(.caption).foregroundStyle(LeafColor.terracotta).accessibilityHidden(true)
                    }
                }
                Text(plant.commonName ?? plant.category.label)
                    .font(LeafFont.footnote)
                    .foregroundStyle(LeafColor.textSecondary)
                Text(nextCareSummary(plant))
                    .font(LeafFont.caption)
                    .foregroundStyle(LeafColor.primary)
            }
            .lineLimit(1)
            Spacer(minLength: 0)
            if showsChevron {
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(LeafColor.textTertiary).accessibilityHidden(true)
            }
        }
        .padding(.vertical, LeafSpacing.xxs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(plant.name), \(plant.category.label). \(nextCareSummary(plant))\(plant.isFavorite ? ". Favourite" : "")")
    }
}
