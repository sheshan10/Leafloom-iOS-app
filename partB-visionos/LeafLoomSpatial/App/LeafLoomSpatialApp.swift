import SwiftUI

enum SceneID {
    static let main = "main"
    static let planter = "planter"
    static let room = "room"
}

@main
struct LeafLoomSpatialApp: App {
    @State private var store = GardenStore()
    @State private var immersionStyle: ImmersionStyle = .mixed

    var body: some Scene {
        WindowGroup(id: SceneID.main) {
            GardenWindowView()
                .environment(store)
        }
        .defaultSize(width: 980, height: 640)

        WindowGroup(id: SceneID.planter, for: UUID.self) { $plantID in
            PlanterVolumeView(plantID: plantID)
                .environment(store)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 0.5, height: 0.6, depth: 0.5, in: .meters)

        ImmersiveSpace(id: SceneID.room) {
            RoomImmersiveView()
                .environment(store)
        }
        .immersionStyle(selection: $immersionStyle, in: .mixed)
    }
}
