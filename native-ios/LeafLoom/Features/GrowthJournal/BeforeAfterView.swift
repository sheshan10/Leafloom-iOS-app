import SwiftUI

/// Drag the handle to reveal the earliest photo (left) against the latest (right).
/// VoiceOver users adjust the split with swipe up/down.
struct BeforeAfterView: View {
    let beforeFilename: String?
    let afterFilename: String?
    let category: PlantCategory
    @State private var split: CGFloat = 0.5

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .leading) {
                PlantThumbnail(imageFilename: afterFilename, category: category, cornerRadius: 0)
                PlantThumbnail(imageFilename: beforeFilename, category: category, cornerRadius: 0)
                    .mask(alignment: .leading) {
                        Rectangle().frame(width: width * split)
                    }
                Rectangle()
                    .fill(.white)
                    .frame(width: 3)
                    .shadow(radius: 2)
                    .overlay {
                        Image(systemName: "arrow.left.and.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(LeafColor.forest)
                            .frame(width: 34, height: 34)
                            .background(.white, in: Circle())
                            .shadow(radius: 3)
                    }
                    .offset(x: width * split - 1.5)
            }
            .overlay(alignment: .topLeading) { tag("Before").padding(LeafSpacing.sm) }
            .overlay(alignment: .topTrailing) { tag("After").padding(LeafSpacing.sm) }
            .clipShape(RoundedRectangle(cornerRadius: LeafRadius.xl, style: .continuous))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in split = min(max(value.location.x / max(width, 1), 0.05), 0.95) }
            )
        }
        .accessibilityElement()
        .accessibilityLabel("Before and after comparison")
        .accessibilityValue("Showing \(Int(split * 100)) percent before photo")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: split = min(split + 0.1, 0.95)
            case .decrement: split = max(split - 0.1, 0.05)
            @unknown default: break
            }
        }
    }

    private func tag(_ text: String) -> some View {
        Text(text)
            .font(LeafFont.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, LeafSpacing.xs)
            .padding(.vertical, 3)
            .background(.black.opacity(0.5), in: Capsule())
            .accessibilityHidden(true)
    }
}
