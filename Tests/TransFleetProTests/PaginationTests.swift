import XCTest
@testable import TransFleetProApp

final class PaginationTests: XCTestCase {

    func testPaginationClampingWhenItemsDecrease() {
        var state = PaginationState()
        state.itemsPerPage = 10
        state.currentPage = 5 // User was on page 5 with 50 items

        let smallItems = Array(1...8) // Now items count shrunk to 8
        let pageSlice = state.page(smallItems)

        XCTAssertFalse(pageSlice.isEmpty, "Page slice should not be empty when total items > 0")
        XCTAssertEqual(Array(pageSlice), smallItems, "Should clamp currentPage to 1 and return all 8 items")
        XCTAssertEqual(state.validCurrentPage(for: smallItems.count), 1)
    }

    func testPaginationNormalSlicing() {
        var state = PaginationState()
        state.itemsPerPage = 10
        state.currentPage = 2

        let items = Array(1...25)
        let pageSlice = state.page(items)

        XCTAssertEqual(Array(pageSlice), Array(11...20))
    }

    func testPaginationEmptyItems() {
        var state = PaginationState()
        state.currentPage = 3
        let emptyItems: [Int] = []
        let pageSlice = state.page(emptyItems)

        XCTAssertTrue(pageSlice.isEmpty)
    }
}
