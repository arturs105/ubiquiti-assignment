import Foundation
import Testing
@testable import Ubiquiti_Assignment

struct ProductCategoryTests {
    @Test func allHoldsEveryProductWhateverItsLine() {
        let products = Product.previews + [Product.placeholder]

        #expect(products.allSatisfy(ProductCategory.all.contains))
    }

    @Test func camerasIsTheProtectLine() {
        #expect(ProductCategory.cameras.contains(product(line: .unifiProtect)))
        #expect(!ProductCategory.cameras.contains(product(line: .unifiConnect)))
        #expect(!ProductCategory.cameras.contains(product(line: Line.ID(rawValue: "unifi-network"))))
    }

    @Test(arguments: [Line.ID.unifiConnect, .unifiAccess, .unifiLED, .unifiTalk, .mfi])
    func iotHoldsTheFiveIoTLines(line: Line.ID) {
        #expect(ProductCategory.iot.contains(product(line: line)))
    }

    @Test(arguments: [Line.ID.unifiProtect, .unknown, Line.ID(rawValue: "unifi-network"), Line.ID(rawValue: "airmax")])
    func iotLeavesOtherLinesToAll(line: Line.ID) {
        #expect(!ProductCategory.iot.contains(product(line: line)))
    }

    @Test func aCameraRecordedUnderAnotherLineIsNotACamera() {
        // The rule is the line, not the device type; see `docs/DECISIONS.md`, 2026-10-15.
        let networkCamera = product(line: Line.ID(rawValue: "unifi-network"), deviceType: "camera")

        #expect(!ProductCategory.cameras.contains(networkCamera))
    }

    @Test func tabsAreAllCamerasIoTInOrder() {
        #expect(ProductCategory.allCases == [.all, .cameras, .iot])
    }

    private func product(line: Line.ID, deviceType: String = "unknown") -> Product {
        Product(
            id: UUID(),
            name: "Product",
            abbreviation: "P",
            sku: "SKU",
            deviceType: deviceType,
            defaultImageID: "image",
            line: Line(id: line, name: line.rawValue),
        )
    }
}
