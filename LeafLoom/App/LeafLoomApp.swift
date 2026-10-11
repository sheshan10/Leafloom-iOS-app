import SwiftUI

@main
struct LeafLoomApp: App {
    @State private var env = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(env)
                .environment(env.router)
                .environment(env.toasts)
                .environment(env.preferences)
                .environment(\.managedObjectContext, env.viewContext)
                .preferredColorScheme(env.preferences.theme.colorScheme)
                .tint(LeafColor.primary)
        }
    }
}
