import SwiftUI

/// The care summary shown in the window, under the volume and above plants in the room.
struct CareCardView: View {
    @Environment(GardenStore.self) private var store
    let plant: SpatialPlant
    var compact = false

    var body: some View {
        let available = store.light(for: plant.id)
        let fit = store.fit(for: plant)
        VStack(alignment: .leading, spacing: compact ? 6 : 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(plant.name).font(compact ? .headline : .title2.bold())
                Text(plant.commonName).font(.subheadline).foregroundStyle(.secondary)
            }
            FitBadge(fit: fit)
            if !compact {
                LabeledContent {
                    Text(plant.sunlight.label)
                } label: {
                    Label("Prefers", systemImage: plant.sunlight.symbol)
                }
                LabeledContent {
                    Text(available.label)
                } label: {
                    Label("Here (estimate)", systemImage: available.symbol)
                }
                if let advice = LightFit.advice(preferred: plant.sunlight, available: available) {
                    Text(advice).font(.callout)
                }
            }
            WateringLine(plant: plant)
            if !compact {
                Text(plant.tip).font(.callout).foregroundStyle(.secondary)
            }
        }
        .padding(compact ? 14 : 20)
        .frame(width: compact ? 240 : nil, alignment: .leading)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct FitBadge: View {
    let fit: LightFit

    var body: some View {
        Label(fit.label, systemImage: fit.symbol)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(tint.opacity(0.25), in: Capsule())
            .foregroundStyle(tint)
    }

    private var tint: Color {
        switch fit {
        case .good: .green
        case .acceptable: .yellow
        case .poor: .red
        }
    }
}

struct WateringLine: View {
    let plant: SpatialPlant

    var body: some View {
        let next = plant.nextWatering()
        Label {
            if plant.isWateringDue() {
                Text("Water today").bold()
            } else {
                Text("Water \(next, format: .relative(presentation: .named))")
            }
        } icon: {
            Image(systemName: "drop.fill").foregroundStyle(.cyan)
        }
        .font(.callout)
    }
}
