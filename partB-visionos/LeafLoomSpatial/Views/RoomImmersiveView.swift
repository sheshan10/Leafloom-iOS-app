import RealityKit
import SwiftUI

/// Mixed-immersion room: every plant stands on the real floor and can be dragged, rotated and
/// scaled. A draggable window marker drives the light-zone estimate shown on each plant's tag.
struct RoomImmersiveView: View {
    @Environment(GardenStore.self) private var store
    @State private var root = Entity()
    @State private var gestureStart: [UUID: Placement] = [:]

    private let tagLift: Float = 0.12

    var body: some View {
        RealityView { content, attachments in
            content.add(root)
            let window = PlantEntityFactory.makeWindowMarker()
            root.addChild(window)
            for plant in store.plants {
                root.addChild(PlantEntityFactory.makePlant(plant))
                if let tag = attachments.entity(for: plant.id) {
                    tag.name = "tag-\(plant.id.uuidString)"
                    tag.components.set(BillboardComponent())
                    root.addChild(tag)
                }
            }
        } update: { _, attachments in
            root.findEntity(named: "window")?.position = store.windowPosition
            for plant in store.plants {
                guard let entity = root.findEntity(named: plant.id.uuidString) else { continue }
                let placement = store.placement(for: plant.id)
                entity.position = placement.position
                entity.orientation = simd_quatf(angle: placement.yaw, axis: [0, 1, 0])
                entity.scale = SIMD3(repeating: placement.scale)
                PlantEntityFactory.setFit(store.fit(for: plant), selected: plant.id == store.selectedID, on: entity)
                if let tag = attachments.entity(for: plant.id) {
                    let top = entity.visualBounds(relativeTo: root).max.y
                    tag.position = SIMD3(placement.position.x, top + tagLift, placement.position.z)
                }
            }
        } attachments: {
            ForEach(store.plants) { plant in
                Attachment(id: plant.id) {
                    RoomTag(plant: plant, selected: plant.id == store.selectedID)
                }
            }
        }
        .gesture(dragGesture)
        .simultaneousGesture(rotateGesture)
        .simultaneousGesture(magnifyGesture)
        .simultaneousGesture(tapGesture)
        .onAppear { store.isRoomOpen = true }
        .onDisappear { store.isRoomOpen = false }
    }

    // MARK: Gestures

    private enum Target {
        case plant(UUID)
        case window
    }

    /// Hits land on the collision entity (the plant root or the window pane); walk up to the
    /// named root to find what was touched.
    private func target(of entity: Entity) -> (Target, Entity)? {
        var current: Entity? = entity
        while let node = current {
            if node.name == "window" { return (.window, node) }
            if let id = UUID(uuidString: node.name), store.plant(id: id) != nil { return (.plant(id), node) }
            current = node.parent
        }
        return nil
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                guard let hit = target(of: value.entity), let parent = hit.1.parent else { return }
                let point = value.convert(value.location3D, from: .local, to: parent)
                switch hit.0 {
                case .plant(let id):
                    store.selectedID = id
                    let current = store.placement(for: id).position
                    store.move(id, to: SIMD3(point.x, current.y, point.z), persist: false)
                case .window:
                    store.moveWindow(to: point, persist: false)
                }
            }
            .onEnded { _ in store.commitLayout() }
    }

    private var rotateGesture: some Gesture {
        RotateGesture3D(constrainedToAxis: .y)
            .targetedToAnyEntity()
            .onChanged { value in
                guard case .plant(let id)? = target(of: value.entity)?.0 else { return }
                let start = gestureStart[id] ?? store.placement(for: id)
                gestureStart[id] = start
                let rotation = value.rotation
                let sign: Float = rotation.axis.y < 0 ? -1 : 1
                store.rotate(id, toYaw: start.yaw + sign * Float(rotation.angle.radians), persist: false)
            }
            .onEnded { _ in
                gestureStart.removeAll()
                store.commitLayout()
            }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                guard case .plant(let id)? = target(of: value.entity)?.0 else { return }
                let start = gestureStart[id] ?? store.placement(for: id)
                gestureStart[id] = start
                store.scale(id, to: start.scale * Float(value.magnification), persist: false)
            }
            .onEnded { _ in
                gestureStart.removeAll()
                store.commitLayout()
            }
    }

    private var tapGesture: some Gesture {
        SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                if case .plant(let id)? = target(of: value.entity)?.0 { store.selectedID = id }
            }
    }
}

/// Floating label above each plant. The selected plant expands into a full care card.
private struct RoomTag: View {
    @Environment(GardenStore.self) private var store
    let plant: SpatialPlant
    let selected: Bool

    var body: some View {
        if selected {
            CareCardView(plant: plant, compact: true)
        } else {
            HStack(spacing: 6) {
                Image(systemName: store.fit(for: plant).symbol)
                Text(plant.name).font(.headline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .glassBackgroundEffect(in: Capsule())
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(plant.name), \(store.fit(for: plant).label)")
        }
    }
}
