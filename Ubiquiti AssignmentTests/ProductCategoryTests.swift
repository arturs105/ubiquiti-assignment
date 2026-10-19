import Foundation
import Testing
@testable import Ubiquiti_Assignment

struct ProductCategoryTests {
    @Test func allHoldsEveryProductWhateverItsLine() {
        let products = Product.previews + [Product.placeholder]

        #expect(products.allSatisfy(ProductCategory.all.contains))
    }

    @Test func camerasIsTheCameraDeviceType() {
        // The rule is the device type, not the line; see `docs/DECISIONS.md`, 2026-10-19.
        #expect(ProductCategory.cameras.contains(product(line: .unifiProtect, deviceType: .camera)))
        #expect(!ProductCategory.cameras.contains(product(line: .unifiProtect, deviceType: sensor)))
        #expect(ProductCategory.cameras.contains(product(line: .unifiConnect, deviceType: .camera)))
        #expect(!ProductCategory.cameras.contains(product(line: .unifiConnect)))
    }

    @Test(arguments: [Line.ID.unifiConnect, .unifiAccess, .unifiLED, .unifiTalk, .mfi])
    func iotHoldsTheFiveIoTLines(line: Line.ID) {
        #expect(ProductCategory.iot.contains(product(line: line)))
    }

    @Test(arguments: [Line.ID.unifiProtect, .unknown, Line.ID(rawValue: "unifi-network"), Line.ID(rawValue: "airmax")])
    func iotLeavesOtherLinesToAll(line: Line.ID) {
        #expect(!ProductCategory.iot.contains(product(line: line)))
    }

    @Test func tabsAreAllCamerasIoTInOrder() {
        #expect(ProductCategory.allCases == [.all, .cameras, .iot])
    }

    private let sensor = Product.DeviceType(rawValue: "sensor")

    private func product(line: Line.ID, deviceType: Product.DeviceType = .init(rawValue: "unknown")) -> Product {
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
