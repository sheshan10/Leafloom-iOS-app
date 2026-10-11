import XCTest
@testable import LeafLoom

final class PlantQueryTests: XCTestCase {
    private let monty = PlantSnapshot(plantName: "Monty", plantCommonName: "Swiss cheese plant", plantScientificName: "Monstera deliciosa", plantCategory: .foliage, plantLocation: "Living room", plantTags: ["statement"], plantIsFavorite: true, plantDateAdded: Fixtures.daysFromNow(-150))
    private let sunny = PlantSnapshot(plantName: "Sunny", plantCommonName: "Snake plant", plantScientificName: "Dracaena trifasciata", plantCategory: .succulent, plantLocation: "Bedroom", plantTags: ["low-maintenance"], plantDateAdded: Fixtures.daysFromNow(-120))
    private let aloe = PlantSnapshot(plantName: "aloe", plantCommonName: "Aloe vera", plantScientificName: "Aloe vera", plantCategory: .succulent, plantLocation: "Kitchen window", plantDateAdded: Fixtures.daysFromNow(-30))
    private let cafe = PlantSnapshot(plantName: "Café fern", plantCategory: .fern, plantDateAdded: Fixtures.daysFromNow(-1))

    private var all: [PlantSnapshot] { [monty, sunny, aloe, cafe] }

    func testSearchMatchesAllNameFieldsAndTags() {
        XCTAssertTrue(PlantQuery.matches(monty, search: "MONSTERA"))
        XCTAssertTrue(PlantQuery.matches(monty, search: "cheese"))
        XCTAssertTrue(PlantQuery.matches(monty, search: "statem"))
        XCTAssertTrue(PlantQuery.matches(cafe, search: "cafe"), "Diacritic-insensitive")
        XCTAssertTrue(PlantQuery.matches(sunny, search: "   "), "Blank search matches everything")
        XCTAssertFalse(PlantQuery.matches(sunny, search: "basil"))
    }

    func testCategoryLocationAndFavouriteFilters() {
        var q = PlantQuery()
        q.categories = [.succulent]
        XCTAssertEqual(Set(q.apply(to: all).map(\.plantName)), ["Sunny", "aloe"])

        q.location = "Bedroom"
        XCTAssertEqual(q.apply(to: all).map(\.plantName), ["Sunny"])

        q = PlantQuery()
        q.favoritesOnly = true
        XCTAssertEqual(q.apply(to: all).map(\.plantName), ["Monty"])
        XCTAssertTrue(q.isFiltering)
        XCTAssertFalse(PlantQuery().isFiltering)
    }

    func testSorts() {
        var q = PlantQuery()
        q.sort = .recent
        XCTAssertEqual(q.apply(to: all).map(\.plantName), ["Café fern", "aloe", "Sunny", "Monty"])

        q.sort = .alphabetical
        XCTAssertEqual(q.apply(to: all).map(\.plantName), ["aloe", "Café fern", "Monty", "Sunny"], "Case-insensitive A–Z")

        q.sort = .nextCare
        let next: [UUID: Date] = [sunny.plantID: Fixtures.daysFromNow(1), monty.plantID: Fixtures.daysFromNow(3)]
        XCTAssertEqual(q.apply(to: all, nextCare: next).map(\.plantName), ["Sunny", "Monty", "aloe", "Café fern"], "Plants without care last, then by name")
    }

    func testNextCareIndexUsesEarliestOpenTask() {
        let id = UUID()
        let tasks = [
            CareTaskSnapshot(taskPlantID: id, taskDueDate: Fixtures.daysFromNow(5)),
            CareTaskSnapshot(taskPlantID: id, taskDueDate: Fixtures.daysFromNow(2)),
            CareTaskSnapshot(taskPlantID: id, taskDueDate: Fixtures.daysFromNow(-1), taskIsCompleted: true),
            CareTaskSnapshot(taskPlantID: nil, taskDueDate: Fixtures.daysFromNow(-5)),
        ]
        XCTAssertEqual(PlantQuery.nextCareIndex(tasks), [id: Fixtures.daysFromNow(2)])
    }

    func testDistinctLocations() {
        let blank = PlantSnapshot(plantName: "X", plantLocation: "  ")
        XCTAssertEqual(PlantQuery.distinctLocations(all + [blank, monty]), ["Bedroom", "Kitchen window", "Living room"])
    }
}
