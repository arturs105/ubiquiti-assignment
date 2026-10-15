import Foundation
import Testing
@testable import Ubiquiti_Assignment

struct FeedDecodingTests {
    @Test func fixtureDecodesEveryProduct() throws {
        let feed = try decodeFixture()

        #expect(feed.version == "ff4e56c5856d96e3b801dbf379cf026b1099f786")
        #expect(feed.products.count == 12)
    }

    @Test func requiredFieldsAreFlattenedFromTheFeedNesting() throws {
        let camera = try product(FixtureID.g3Dome)

        #expect(camera.name == "Camera G3 Dome")
        #expect(camera.abbreviation == "G3 Dome")
        #expect(camera.sku == "UVC-G3-Dome")
        #expect(camera.deviceType == "camera")
        #expect(camera.shortnames == ["UVC G3 Dome", "UVC-G3-Dome"])
        #expect(camera.defaultImageID == "d8594ad6c9cf32910b210da58ace5d25")
        #expect(camera.line == Line(id: .unifiProtect, name: "UniFi Protect"))
    }

    @Test func cameraDetailsComeFromTheProtectBlock() throws {
        let camera = try product(FixtureID.g3Dome)

        #expect(camera.adoptability == .adoptable)
        #expect(camera.fieldOfView == 87.8)
        #expect(camera.suggestedDistance == 5)
        #expect(camera.complianceModelName == "UVC-G3-DOME")
        #expect(camera.baseConsumptionWatts == nil)
        #expect(camera.minimumAdoptVersion == nil)
        #expect(camera.isARSupported == nil)
    }

    @Test(arguments: [(FixtureID.flexMini, 2.5), (FixtureID.proHD24PoE, 60)] as [(UUID, Double)])
    func powerConsumptionAcceptsDecimalAndIntegerWatts(id: UUID, watts: Double) throws {
        #expect(try product(id).baseConsumptionWatts == watts)
    }

    @Test(arguments: [(FixtureID.proHD24PoE, "8.4.59"), (FixtureID.envrCore, "7.0.104")] as [(UUID, String)])
    func minimumAdoptVersionReadsTheNetOrProtectKey(id: UUID, version: String) throws {
        #expect(try product(id).minimumAdoptVersion == version)
    }

    @Test func standaloneProductsAndARSupportDecode() throws {
        #expect(try product(FixtureID.envrCore).adoptability == .standalone)
        #expect(try product(FixtureID.avFiber).isARSupported == true)
    }

    @Test func indoorOnlyAndWiFiGenerationComeFromTheComplianceBlock() throws {
        let accessPoint = try product(FixtureID.u6Enterprise)
        let displayCast = try product(FixtureID.displayCast)

        #expect(accessPoint.isIndoorOnly == true)
        #expect(accessPoint.wifiGeneration == "6e")
        #expect(displayCast.isIndoorOnly == nil)
        #expect(displayCast.wifiGeneration == "5e")
    }

    @Test func detailsAreNilWhenTheFeedHasOnlyRequiredKeys() throws {
        let antenna = try product(FixtureID.antenna)

        #expect(antenna.adoptability == nil)
        #expect(antenna.fieldOfView == nil)
        #expect(antenna.suggestedDistance == nil)
        #expect(antenna.baseConsumptionWatts == nil)
        #expect(antenna.minimumAdoptVersion == nil)
        #expect(antenna.complianceModelName == nil)
        #expect(antenna.isARSupported == nil)
        #expect(antenna.isIndoorOnly == nil)
        #expect(antenna.wifiGeneration == nil)
    }

    @Test func unknownAdoptabilityDecodesToNil() throws {
        let feed = try decode(products: [minimalProduct(extra: #""unifi": {"adoptability": "cloud-managed"}"#)])

        #expect(feed.products.count == 1)
        #expect(feed.products.first?.adoptability == nil)
    }

    @Test func malformedProductIsDroppedAndTheRestSurvive() throws {
        let missingID = #"""
        {"product": {"name": "No id", "abbrev": "N"}, "sku": "N", "deviceType": "x", "shortnames": [],
         "images": {"default": "a"}, "line": {"id": "airmax", "name": "airMAX"}}
        """#
        let productNotAnObject = #"""
        {"id": "00000000-0000-0000-0000-000000000002", "product": "flat", "sku": "F", "deviceType": "x",
         "shortnames": [], "images": {"default": "a"}, "line": {"id": "airmax", "name": "airMAX"}}
        """#
        let nonUUIDID = minimalProduct(id: "not-a-uuid")

        let feed = try decode(products: [
            minimalProduct(),
            missingID,
            productNotAnObject,
            nonUUIDID,
            minimalProduct(id: "00000000-0000-0000-0000-000000000003"),
        ])

        #expect(feed.products.map(\.id) == [
            UUID(uuidString: "00000000-0000-0000-0000-000000000001"),
            UUID(uuidString: "00000000-0000-0000-0000-000000000003"),
        ])
    }

    @Test func unknownLineDecodesLikeAnyOther() throws {
        let feed = try decode(products: [minimalProduct(line: #"{"id": "unifi-teleport", "name": "UniFi Teleport"}"#)])

        #expect(feed.products.first?.line == Line(id: Line.ID(rawValue: "unifi-teleport"), name: "UniFi Teleport"))
    }

    @Test func placeholderProductDecodes() throws {
        let placeholder = try product(FixtureID.unknownDevice)

        #expect(placeholder.name == "Unknown Device")
        #expect(placeholder.line.id == .unknown)
    }

    @Test func everyFixtureProductSurvivesAnEncodeDecodeRoundTrip() throws {
        let feed = try decodeFixture()

        let encoded = try JSONEncoder().encode(feed)
        let decoded = try JSONDecoder().decode(Feed.self, from: encoded)

        #expect(decoded == feed)
    }

    // MARK: - Helpers

    /// Ids of fixture products, one per modelled shape.
    private nonisolated enum FixtureID {
        static let g3Dome = UUID(uuidString: "e8006f66-1914-4159-b01d-a9a2fa8a4ec2")!
        static let flexMini = UUID(uuidString: "b13610ef-7e73-4a14-985a-53bb75a62401")!
        static let proHD24PoE = UUID(uuidString: "6a903417-d0f2-6fd4-fd83-145a46794d15")!
        static let envrCore = UUID(uuidString: "85a45409-3154-4bd2-931c-49bf4da0117c")!
        static let avFiber = UUID(uuidString: "e006afb6-1e29-4000-9c4d-311d0d11644b")!
        static let antenna = UUID(uuidString: "e9d2b791-482e-449c-b9f8-41b304b884fe")!
        static let unknownDevice = UUID(uuidString: "4a1e2102-3c54-48d6-b90f-535293d31cbe")!
        static let displayCast = UUID(uuidString: "b29bcbf8-1e1f-4405-9bee-573837f40255")!
        static let u6Enterprise = UUID(uuidString: "6b036438-7ceb-464b-97e7-d681054e41bb")!
    }

    private func product(_ id: UUID) throws -> Product {
        try #require(try decodeFixture().products.first { $0.id == id })
    }

    private func decodeFixture() throws -> Feed {
        let url = try #require(Bundle(for: FixtureLocator.self).url(forResource: "feed-fixture", withExtension: "json"))
        return try JSONDecoder().decode(Feed.self, from: Data(contentsOf: url))
    }

    /// A feed document whose `devices` array holds the given product JSON literals.
    private func decode(products: [String]) throws -> Feed {
        let json = #"{"version": "v1", "devices": [\#(products.joined(separator: ", "))]}"#
        return try JSONDecoder().decode(Feed.self, from: Data(json.utf8))
    }

    /// A product with only the required keys, plus any `extra` top-level members.
    private func minimalProduct(
        id: String = "00000000-0000-0000-0000-000000000001",
        line: String = #"{"id": "airmax", "name": "airMAX"}"#,
        extra: String = "",
    ) -> String {
        let tail = extra.isEmpty ? "" : ", " + extra
        return #"""
        {"id": "\#(id)", "product": {"name": "Minimal", "abbrev": "Min"}, "sku": "MIN", "deviceType": "tool",
         "shortnames": ["MIN"], "images": {"default": "0"}, "line": \#(line)\#(tail)}
        """#
    }
}

/// Anchors `Bundle(for:)` to the test bundle; Swift Testing suites are structs.
private final class FixtureLocator {}
