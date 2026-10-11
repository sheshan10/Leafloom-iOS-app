import CoreData
import SwiftUI

/// Onboarding gate → main tabs. Shows a recoverable error if the data store could not be opened.
struct RootView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(AppPreferences.self) private var preferences
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if let error = env.startupError {
                ErrorStateView(title: "LeafLoom couldn’t open your garden", message: error)
                    .leafScreenBackground()
            } else if !preferences.onboardingComplete {
                OnboardingView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(.easeInOut(duration: LeafMotion.slow), value: preferences.onboardingComplete)
    }
}

struct MainTabView: View {
    @Environment(AppRouter.self) private var router
    @FetchRequest(sortDescriptors: [], predicate: NSPredicate(format: "isCompleted == NO"))
    private var openTasks: FetchedResults<CareTask>

    private var careBadge: Int {
        openTasks.filter { CareStatusEvaluator.needsAttention($0) }.count
    }

    var body: some View {
        @Bindable var router = router
        ZStack {
            ForEach(AppTab.allCases) { tab in
                let selected = router.selectedTab == tab
                TabStack(tab: tab)
                    .opacity(selected ? 1 : 0)
                    .allowsHitTesting(selected)
                    .accessibilityHidden(!selected)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(badges: [.care: careBadge])
        }
        .overlay { ToastOverlay() }
        .sheet(item: $router.sheet) { sheet in
            SheetHost(sheet: sheet)
        }
    }
}

/// One NavigationStack per tab so each tab keeps its own history.
private struct TabStack: View {
    let tab: AppTab
    @Environment(AppRouter.self) private var router

    var body: some View {
        NavigationStack(path: router.binding(for: tab)) {
            root
                .navigationDestination(for: Route.self) { route in
                    RouteDestination(route: route)
                }
        }
    }

    @ViewBuilder private var root: some View {
        switch tab {
        case .home: DashboardView()
        case .plants: PlantCollectionView()
        case .identify: IdentifyView()
        case .care: CareTaskListView()
        case .insights: InsightsView()
        }
    }
}

struct RouteDestination: View {
    let route: Route

    var body: some View {
        switch route {
        case let .plantDetails(id): PlantDetailView(plantID: id)
        case let .taskDetails(id): CareTaskDetailView(taskID: id)
        case let .journal(id): GrowthJournalView(plantID: id)
        case .settings: SettingsView()
        case .reminderSettings: ReminderSettingsView()
        case .about: AboutView()
        }
    }
}

/// Resolves the record being edited here, where the environment is available, so forms start populated.
private struct SheetHost: View {
    let sheet: SheetRoute
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        switch sheet {
        case let .addPlant(prefill, identificationID):
            PlantFormView(mode: .create(prefill: prefill, identificationID: identificationID))
        case let .editPlant(id):
            PlantFormView(mode: .edit(id), existing: env.plants.plant(id: id))
        case let .addTask(plantID):
            CareTaskFormView(mode: .create(plantID: plantID), defaultHour: env.preferences.reminderHour)
        case let .editTask(id):
            CareTaskFormView(mode: .edit(id), existing: env.tasks.task(id: id))
        case let .addJournal(plantID):
            JournalEntryFormView(mode: .create(plantID: plantID))
        case let .editJournal(id):
            JournalEntryFormView(mode: .edit(id), existing: env.journal.entry(id: id))
        }
    }
}
