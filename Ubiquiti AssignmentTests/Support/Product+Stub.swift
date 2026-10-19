import Foundation
@testable import Ubiquiti_Assignment

extension Product {
    /// A product with only the required keys, decoded from feed JSON because `Product` has no memberwise
    /// initialiser. A fresh id per call, so image URLs built from it are unique across parallel tests.
    static func stub(id: UUID = UUID(), defaultImageID: String = "0") throws -> Product {
        let json = #"""
        {"id": "\#(id.uuidString)", "product": {"name": "Stub", "abbrev": "Stub"}, "sku": "STUB", "deviceType": "tool",
         "shortnames": ["STUB"], "images": {"default": "\#(defaultImageID)"}, "line": {"id": "airmax", "name": "airMAX"}}
        """#
        return try JSONDecoder().decode(Product.self, from: Data(json.utf8))
    }
}
