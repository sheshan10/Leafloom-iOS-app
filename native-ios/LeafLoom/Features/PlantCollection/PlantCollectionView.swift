import CoreData
import SwiftUI

struct PlantCollectionView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(AppRouter.self) private var router
    @Environment(AppPreferences.self) private var preferences
    @FetchRequest(sortDescriptors: [SortDescriptor(\Plant.dateAdded, order: .reverse)])
    private var plants: FetchedResults<Plant>
    @FetchRequest(sortDescriptors: [], predicate: NSPredicate(format: "isCompleted == NO"))
    private var openTasks: FetchedResults<CareTask>
    @State private var query = PlantQuery()
    @State private var showFilters = false

    var body: some View {
        let nextCare = PlantQuery.nextCareIndex(Array(openTasks))
        let results = query.apply(to: Array(plants), nextCare: nextCare)
        let locations = PlantQuery.distinctLocations(Array(plants))

        ScrollView {
            VStack(alignment: .leading, spacing: LeafSpacing.md) {
                filterBar(locations: locations)

                if plants.isEmpty {
                    EmptyStateView(
                        illustration: "EmptyPlants",
                        title: "No plants yet",
                        message: "Add your first plant, or identify one from a photo.",
                        actionTitle: "Add plant"
                    ) { router.present(.addPlant()) }
                } else if results.isEmpty {
                    EmptyStateView(
                        illustration: "EmptySearch",
                        title: "No matching plants",
                        message: "Try a different search or clear the filters.",
                        actionTitle: "Clear filters"
                    ) { query = PlantQuery(sort: query.sort) }
                } else {
                    Text("\(results.count) of \(plants.count) plants")
                        .font(LeafFont.footnote)
                        .foregroundStyle(LeafColor.textSecondary)
                        .accessibilityIdentifier("collection.count")
                    if preferences.collectionLayout == .grid {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 158), spacing: LeafSpacing.sm)], spacing: LeafSpacing.sm) {
                            ForEach(results) { plant in
                                NavigationLink(value: Route.plantDetails(plant.id)) {
                                    PlantCardView(plant: plant) { env.toggleFavorite(plant) }
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("plantCard")
                                .contextMenu { contextMenu(for: plant) }
                            }
                        }
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(results) { plant in
                                NavigationLink(value: Route.plantDetails(plant.id)) {
                                    PlantRowView(plant: plant)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("plantCard")
                                .padding(.vertical, LeafSpacing.xxs)
                                .contextMenu { contextMenu(for: plant) }
                                if plant.id != results.last?.id { Divider().padding(.leading, 68) }
                            }
                        }
                        .leafCard(padding: LeafSpacing.sm)
                    }
                }
            }
            .padding(.horizontal, LeafSpacing.screen)
            .padding(.bottom, LeafSpacing.xl)
            .leafAnimation(value: results.map(\.id))
        }
        .leafScreenBackground()
        .navigationTitle("My Plants")
        .searchable(text: $query.search, placement: .navigationBarDrawer(displayMode: .always), prompt: "Name, species or tag")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    preferences.collectionLayout = preferences.collectionLayout == .grid ? .list : .grid
                } label: {
                    Image(systemName: preferences.collectionLayout == .grid ? "list.bullet" : "square.grid.2x2")
                }
                .accessibilityLabel(preferences.collectionLayout == .grid ? "Show as list" : "Show as grid")
                Button { router.present(.addPlant()) } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add plant")
                    .accessibilityIdentifier("collection.add")
            }
        }
        .accessibilityIdentifier("screen.plants")
    }

    @ViewBuilder
    private func filterBar(locations: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LeafSpacing.xs) {
                Menu {
                    Picker("Sort by", selection: $query.sort) {
                        ForEach(PlantSort.allCases) { Text($0.label).tag($0) }
                    }
                } label: {
                    Label(query.sort.label, systemImage: "arrow.up.arrow.down")
                        .font(LeafFont.subheadline.weight(.medium))
                        .padding(.horizontal, LeafSpacing.sm)
                        .frame(minHeight: 36)
                        .background(LeafColor.primarySoft, in: Capsule())
                }
                .accessibilityLabel("Sort by \(query.sort.label)")

                FilterChip(title: "Favourites", systemImage: query.favoritesOnly ? "heart.fill" : "heart", isSelected: query.favoritesOnly) {
                    query.favoritesOnly.toggle()
                }
                ForEach(PlantCategory.allCases) { category in
                    FilterChip(title: category.label, assetImage: category.assetName, isSelected: query.categories.contains(category)) {
                        if query.categories.contains(category) { query.categories.remove(category) } else { query.categories.insert(category) }
                    }
                }
                if !locations.isEmpty {
                    Divider().frame(height: 24)
                    ForEach(locations, id: \.self) { location in
                        FilterChip(title: location, systemImage: "mappin", isSelected: query.location == location) {
                            query.location = query.location == location ? nil : location
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .scrollClipDisabled()
    }

    @ViewBuilder
    private func contextMenu(for plant: Plant) -> some View {
        Button { env.toggleFavorite(plant) } label: {
            Label(plant.isFavorite ? "Remove from favourites" : "Add to favourites", systemImage: plant.isFavorite ? "heart.slash" : "heart")
        }
        Button { router.present(.editPlant(plant.id)) } label: { Label("Edit", systemImage: "pencil") }
        Button { router.present(.addTask(plantID: plant.id)) } label: { Label("Add care task", systemImage: "plus.circle") }
    }
}
