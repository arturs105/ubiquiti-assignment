import Foundation
import Testing
@testable import Ubiquiti_Assignment

struct ProductFilterTests {
    @Test func noCheckedLineKeepsEveryLineUnderTheTab() {
        let filter = ProductFilter(category: .all)

        #expect(Product.previews.allSatisfy(filter.contains))
    }

    @Test func aCheckedLineKeepsOnlyItsProducts() {
        let filter = ProductFilter(category: .all, lines: [.unifiProtect])

        #expect(Product.previews.filter(filter.contains) == [Product.previews[0]])
    }

    @Test func checkedLinesAddUp() {
        let filter = ProductFilter(category: .all, lines: [.unifiProtect, .unifiConnect])

        #expect(Product.previews.filter(filter.contains) == [Product.previews[0], Product.previews[2]])
    }

    @Test func keepingTheOfferedLinesUnchecksTheOthers() {
        let filter = ProductFilter(category: .all, lines: [.unifiProtect, .unifiConnect])

        #expect(filter.keeping([.unifiProtect, .unifiAccess]) == ProductFilter(category: .all, lines: [.unifiProtect]))
    }

    @Test func aCheckedLineOutsideTheTabKeepsNothing() {
        // The tab rules first: a line checked under All does not pull its products into Cameras.
        let filter = ProductFilter(category: .cameras, lines: [.unifiConnect])

        #expect(Product.previews.filter(filter.contains).isEmpty)
    }
}
