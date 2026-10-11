import RealityKit
import SwiftUI

/// A volumetric window holding one plant on a turntable. Drag to spin it, pinch to zoom.
struct PlanterVolumeView: View {
    @Environment(GardenStore.self) private var store
    let plantID: UUID?

    @State private var yaw: Float = 0
    @State private var yawAtGestureStart: Float?
    @State private var zoom: Float = 1
    @State private var zoomAtGestureStart: Float?

    /// The volume is 0.5 m wide; the plant is fitted into this height so tall plants are not clipped.
    private let fitHeight: Float = 0.42

    var body: some View {
        if let plantID, let plant = store.plant(id: plantID) {
            RealityView { content in
                let entity = PlantEntityFactory.makePlant(plant)
                let bounds = entity.visualBounds(relativeTo: nil)
                let fit = fitHeight / max(bounds.extents.y, bounds.extents.x, bounds.extents.z, 0.01)
                let turntable = Entity()
                turntable.name = "turntable"
                turntable.scale = SIMD3(repeating: fit)
                turntable.position.y = -0.27
                turntable.addChild(entity)
                content.add(turntable)
            } update: { content in
                guard let turntable = content.entities.first(where: { $0.name == "turntable" }),
                      let entity = turntable.children.first else { return }
                entity.orientation = simd_quatf(angle: yaw, axis: [0, 1, 0])
                entity.scale = SIMD3(repeating: zoom)
                PlantEntityFactory.setFit(store.fit(for: plant), selected: false, on: entity)
            }
            .gesture(
                DragGesture()
                    .targetedToAnyEntity()
                    .onChanged { value in
                        let start = yawAtGestureStart ?? yaw
                        yawAtGestureStart = start
                        yaw = start + Float(value.translation.width) * 0.01
                    }
                    .onEnded { _ in yawAtGestureStart = nil }
            )
            .simultaneousGesture(
                MagnifyGesture()
                    .targetedToAnyEntity()
                    .onChanged { value in
                        let start = zoomAtGestureStart ?? zoom
                        zoomAtGestureStart = start
                        zoom = min(max(start * Float(value.magnification), 0.6), 1.2)
                    }
                    .onEnded { _ in zoomAtGestureStart = nil }
            )
            .ornament(attachmentAnchor: .scene(.bottom)) {
                CareCardView(plant: plant, compact: true)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("\(plant.name) in 3D")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: yaw += .pi / 8
                case .decrement: yaw -= .pi / 8
                @unknown default: break
                }
            }
        } else {
            ContentUnavailableView("Plant not found", systemImage: "leaf")
        }
    }
}
