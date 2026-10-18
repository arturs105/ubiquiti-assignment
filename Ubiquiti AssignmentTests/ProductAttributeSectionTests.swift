import Foundation
import Testing
@testable import Ubiquiti_Assignment

@MainActor
struct ProductAttributeSectionTests {
    @Test func aProductWithNoDetailsHasOnlyTheGeneralSection() throws {
        let sections = ProductAttributeSection.sections(for: Product.previews[1], locale: english)

        #expect(sections.map(\.group) == [.general])
        let general = try #require(sections.first)
        #expect(general.attributes.map(\.value) == [
            "UniFi", "unifi-network", "Switch Flex Mini", "USW Flex Mini", "USW-Flex-Mini", "switch",
        ])
    }

    @Test func aProductWithEveryDetailHasEverySection() {
        let sections = ProductAttributeSection.sections(for: Product.previews[0], locale: english)

        #expect(sections.map(\.group) == [.general, .unifi, .power, .compliance])
    }

    @Test func theLineNameAndIdAreHighlighted() throws {
        let general = try #require(ProductAttributeSection.sections(for: Product.previews[1], locale: english).first)

        #expect(general.attributes.map(\.isHighlighted) == [true, true, false, false, false, false])
    }

    @Test func shortnamesAndARSupportShowOnlyWhenPresent() throws {
        let general = try #require(ProductAttributeSection.sections(for: Product.previews[0], locale: english).first)

        #expect(general.attributes.map(\.label.key).suffix(2) == ["Also known as", "AR view"])
        #expect(general.attributes.map(\.value).suffix(2) == ["UVC G3 Dome, UVC-G3-DOME", "No"])
    }

    @Test func detailsAreFormattedWithTheirUnits() throws {
        let sections = ProductAttributeSection.sections(for: Product.previews[0], locale: english)
        try #require(sections.count == 4)

        #expect(sections[1].attributes.map(\.value) == ["Adoptable", "1.20.0", "81.3°", "5 m"])
        #expect(sections[2].attributes.map(\.value) == ["4.5 W"])
        #expect(sections[3].attributes.map(\.value) == ["UVC-G3-DOME", "Yes", "5"])
    }

    /// Pinned so the expected strings do not depend on the simulator's locale.
    private let english = Locale(identifier: "en_US")
}
