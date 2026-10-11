import SwiftUI

/// Standard LeafLoom card: surface colour, continuous corners, hairline border and a soft shadow.
struct LeafCardModifier: ViewModifier {
    var padding: CGFloat = LeafSpacing.md
    var radius: CGFloat = LeafRadius.lg

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LeafColor.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(LeafColor.border, lineWidth: 0.5)
            )
            .shadow(color: LeafColor.deep.opacity(0.06), radius: 10, y: 4)
    }
}

/// Animated loading placeholder. Static when Reduce Motion is on.
struct ShimmerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                if !reduceMotion {
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(0.35), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 0.6)
                        .offset(x: phase * geo.size.width * 1.6)
                    }
                    .mask(content)
                }
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) { phase = 1 }
            }
            .accessibilityLabel("Loading")
    }
}

extension View {
    func leafCard(padding: CGFloat = LeafSpacing.md, radius: CGFloat = LeafRadius.lg) -> some View {
        modifier(LeafCardModifier(padding: padding, radius: radius))
    }

    func shimmer() -> some View { modifier(ShimmerModifier()) }

    /// Screen background used by every tab.
    func leafScreenBackground() -> some View {
        background(LeafColor.background.ignoresSafeArea())
    }
}

/// Simple wrapping layout for tags and chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = LeafSpacing.xs

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: min(widest, maxWidth), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
