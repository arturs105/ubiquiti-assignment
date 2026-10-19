import Foundation
import Testing
@testable import Ubiquiti_Assignment

struct ProductImageURLTests {
    @Test func imageServiceURLIsTheResizingCDN() {
        // Evaluates the force-unwrapped literal, so a typo that made it unparseable fails here, not at launch.
        let url = Product.Constants.imageService

        #expect(url.absoluteString == "https://images.svc.ui.com/")
        #expect(url.host() == "images.svc.ui.com")
    }

    @Test func urlFollowsTheAssignmentShapeWithTheWidthOfTheSize() throws {
        let product = try Product.stub(
            id: #require(UUID(uuidString: "cdd9b268-13a2-404f-b295-9e8d0c605de0")),
            defaultImageID: "1435ef4d1b7caf065251ea2fcab512fb",
        )

        let url = product.imageURL(size: .thumbnail)

        #expect(url.absoluteString == """
        https://images.svc.ui.com/?u=https://static.ui.com/fingerprint/ui/images/\
        cdd9b268-13a2-404f-b295-9e8d0c605de0/default/1435ef4d1b7caf065251ea2fcab512fb.png&w=128&q=75
        """)
    }

    @Test(arguments: ImageSize.allCases)
    func widthParameterIsTheSizeInPixels(size: ImageSize) throws {
        let url = try Product.stub().imageURL(size: size)

        let width = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == "w" }?.value
        #expect(width == String(size.pixelWidth))
    }

    @Test func productIDIsLowercasedBecauseTheCDNRejectsUppercase() throws {
        let product = try Product.stub(id: #require(UUID(uuidString: "E8006F66-1914-4159-B01D-A9A2FA8A4EC2")))

        let url = product.imageURL(size: .hero)

        #expect(url.absoluteString.contains("e8006f66-1914-4159-b01d-a9a2fa8a4ec2"))
        #expect(url.absoluteString.contains("E8006F66") == false)
    }
}
