import SwiftUI

/// Circular arc shape whose `progress` is animatable, so the ring fills smoothly.
struct RingArc: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let clamped = min(max(progress, 0), 1)
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: min(rect.width, rect.height) / 2,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + 360 * clamped),
            clockwise: false
        )
        return path
    }
}

/// Weekly care progress ring. Announced to VoiceOver as a percentage with context.
struct ProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 12
    var label: String
    var caption: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(LeafColor.primarySoft, lineWidth: lineWidth)
            RingArc(progress: shown)
                .stroke(
                    AngularGradient(colors: [LeafColor.accent, LeafColor.primary], center: .center, startAngle: .degrees(-90), endAngle: .degrees(270)),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
            VStack(spacing: 0) {
                Text(progress, format: .percent.precision(.fractionLength(0)))
                    .font(LeafFont.metric)
                    .foregroundStyle(LeafColor.text)
                    .contentTransition(.numericText())
                if let caption {
                    Text(caption)
                        .font(LeafFont.caption)
                        .foregroundStyle(LeafColor.textSecondary)
                }
            }
            .minimumScaleFactor(0.6)
            .padding(lineWidth)
        }
        .padding(lineWidth / 2)
        .onAppear { animate(to: progress) }
        .onChange(of: progress) { _, newValue in animate(to: newValue) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(Text(progress, format: .percent.precision(.fractionLength(0))))
    }

    private func animate(to value: Double) {
        if reduceMotion {
            shown = value
        } else {
            withAnimation(.easeOut(duration: LeafMotion.slow * 2)) { shown = value }
        }
    }
}

#Preview {
    ProgressRing(progress: 0.68, label: "Weekly care progress", caption: "this week")
        .frame(width: 140, height: 140)
        .padding()
}
