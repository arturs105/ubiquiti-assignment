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
        #expect(!ProductCategory.cameras.contains(product(line: .unifiProtect, deviceType: .sensor)))
        #expect(ProductCategory.cameras.contains(product(line: .unifiConnect, deviceType: .camera)))
        #expect(!ProductCategory.cameras.contains(product(line: .unifiConnect)))
    }

    @Test(arguments: [Line.ID.unifiConnect, .unifiAccess, .unifiLED, .mfi])
    func iotHoldsTheFourIoTLinesWhateverTheDeviceType(line: Line.ID) {
        #expect(ProductCategory.iot.contains(product(line: line)))
        #expect(ProductCategory.iot.contains(product(line: line, deviceType: .init(rawValue: "power-supply"))))
    }

    @Test(arguments: [Product.DeviceType.sensor, .light, .doorlock, .chime, .alarm])
    func iotHoldsProtectsSensingAndActuatingKinds(kind: Product.DeviceType) {
        #expect(ProductCategory.iot.contains(product(line: .unifiProtect, deviceType: kind)))
    }

    @Test(arguments: [Product.DeviceType.camera, .init(rawValue: "console"), .init(rawValue: "audio")])
    func iotLeavesTheRestOfProtectToAll(kind: Product.DeviceType) {
        #expect(!ProductCategory.iot.contains(product(line: .unifiProtect, deviceType: kind)))
    }

    @Test(arguments: [
        Line.ID(rawValue: "unifi-talk"),
        .unknown,
        Line.ID.unifiNetwork,
        Line.ID(rawValue: "airmax")
    ])
    func iotLeavesOtherLinesToAllEvenForASensor(line: Line.ID) {
        // The device-type rule is Protect's alone; see `docs/DECISIONS.md`, 2026-10-19.
        #expect(!ProductCategory.iot.contains(product(line: line)))
        #expect(!ProductCategory.iot.contains(product(line: line, deviceType: .sensor)))
    }

    @Test func tabsAreAllCamerasIoTInOrder() {
        #expect(ProductCategory.allCases == [.all, .cameras, .iot])
    }

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
