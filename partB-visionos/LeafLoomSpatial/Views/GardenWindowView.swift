import SwiftUI

/// The main window: plant list on the left, care card and spatial actions on the right.
struct GardenWindowView: View {
    @Environment(GardenStore.self) private var store
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var roomError: String?

    var body: some View {
        @Bindable var store = store
        NavigationSplitView {
            List(store.plants, selection: $store.selectedID) { plant in
                PlantRow(plant: plant, fit: store.fit(for: plant))
                    .tag(plant.id)
            }
            .navigationTitle("LeafLoom Spatial")
        } detail: {
            if let plant = store.selectedPlant {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        CareCardView(plant: plant)
                        HStack(spacing: 12) {
                            Button {
                                openWindow(id: SceneID.planter, value: plant.id)
                            } label: {
                                Label("View in 3D", systemImage: "cube")
                            }
                            Button {
                                store.water(plant.id)
                            } label: {
                                Label("Watered today", systemImage: "drop")
                            }
                            .disabled(!plant.isWateringDue())
                        }
                    }
                    .padding(32)
                    .frame(maxWidth: 560, alignment: .leading)
                }
                .navigationTitle(plant.name)
            } else {
                ContentUnavailableView("Choose a plant", systemImage: "leaf", description: Text("Select a plant to see its care card."))
            }
        }
        .ornament(attachmentAnchor: .scene(.bottom)) {
            HStack(spacing: 12) {
                Button {
                    Task { await toggleRoom() }
                } label: {
                    Label(store.isRoomOpen ? "Leave room" : "Arrange in my room",
                          systemImage: store.isRoomOpen ? "xmark.circle" : "square.split.bottomrightquarter")
                }
                Button(role: .destructive) {
                    store.resetLayout()
                } label: {
                    Label("Reset layout", systemImage: "arrow.counterclockwise")
                }
                if !store.plantsNeedingWater.isEmpty {
                    Label("\(store.plantsNeedingWater.count) need water", systemImage: "drop.fill")
                        .font(.callout)
                        .padding(.horizontal, 8)
                }
            }
            .padding(12)
            .glassBackgroundEffect()
        }
        .alert("Couldn't open the room", isPresented: Binding(get: { roomError != nil }, set: { if !$0 { roomError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(roomError ?? "")
        }
    }

    private func toggleRoom() async {
        if store.isRoomOpen {
            await dismissImmersiveSpace()
            return
        }
        switch await openImmersiveSpace(id: SceneID.room) {
        case .opened: break
        case .userCancelled: break
        case .error: roomError = "Another immersive experience may already be open. Close it and try again."
        @unknown default: break
        }
    }
}

private struct PlantRow: View {
    let plant: SpatialPlant
    let fit: LightFit

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .foregroundStyle(.green)
                .frame(width: 36, height: 36)
                .background(.green.opacity(0.15), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(plant.name).font(.headline)
                Text(plant.commonName).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: fit.symbol)
                .foregroundStyle(fit == .good ? Color.green : fit == .acceptable ? Color.yellow : Color.red)
                .accessibilityLabel(fit.label)
        }
        .padding(.vertical, 4)
    }
}
