import Observation
import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home, plants, identify, care, insights

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .plants: "My Plants"
        case .identify: "Identify"
        case .care: "Care"
        case .insights: "Insights"
        }
    }

    var symbol: String {
        switch self {
        case .home: "house"
        case .plants: "leaf"
        case .identify: "viewfinder"
        case .care: "checkmark.circle"
        case .insights: "chart.bar"
        }
    }

    var selectedSymbol: String {
        switch self {
        case .identify: "viewfinder"
        default: symbol + ".fill"
        }
    }
}

enum Route: Hashable {
    case plantDetails(UUID)
    case taskDetails(UUID)
    case journal(UUID)
    case settings
    case reminderSettings
    case about
}

enum SheetRoute: Identifiable, Equatable {
    case addPlant(prefill: PlantDraft? = nil, identificationID: UUID? = nil)
    case editPlant(UUID)
    case addTask(plantID: UUID?)
    case editTask(UUID)
    case addJournal(plantID: UUID?)
    case editJournal(UUID)

    var id: String {
        switch self {
        case .addPlant: "addPlant"
        case let .editPlant(id): "editPlant-\(id)"
        case let .addTask(id): "addTask-\(id?.uuidString ?? "none")"
        case let .editTask(id): "editTask-\(id)"
        case let .addJournal(id): "addJournal-\(id?.uuidString ?? "none")"
        case let .editJournal(id): "editJournal-\(id)"
        }
    }
}

/// Tab selection, one navigation path per tab, and a single sheet slot (no stacked modals).
@Observable
final class AppRouter {
    var selectedTab: AppTab = .home
    var paths: [AppTab: [Route]] = Dictionary(uniqueKeysWithValues: AppTab.allCases.map { ($0, []) })
    var sheet: SheetRoute?

    func binding(for tab: AppTab) -> Binding<[Route]> {
        Binding(
            get: { self.paths[tab] ?? [] },
            set: { self.paths[tab] = $0 }
        )
    }

    /// Selecting the current tab again pops it to its root.
    func select(_ tab: AppTab) {
        if tab == selectedTab {
            paths[tab] = []
        } else {
            selectedTab = tab
        }
    }

    func push(_ route: Route, in tab: AppTab? = nil) {
        let target = tab ?? selectedTab
        if target != selectedTab { selectedTab = target }
        paths[target, default: []].append(route)
    }

    func pop() {
        guard var path = paths[selectedTab], !path.isEmpty else { return }
        path.removeLast()
        paths[selectedTab] = path
    }

    func present(_ sheet: SheetRoute) { self.sheet = sheet }
    func dismissSheet() { sheet = nil }

    /// After "Save to My Plants" from Identify: show the new plant in the My Plants tab.
    func showNewPlant(_ id: UUID) {
        sheet = nil
        paths[.identify] = []
        selectedTab = .plants
        paths[.plants] = [.plantDetails(id)]
    }

    func reset() {
        sheet = nil
        selectedTab = .home
        for tab in AppTab.allCases { paths[tab] = [] }
    }
}
