import SwiftUI

/// Placeholder for the product list: a titled list of static rows that each push a product route.
///
/// Exists so the shell's navigation runs end to end. The real screen, with its view model and Combine pipeline,
/// replaces the body here; the rows then come from the feed instead of `Constants`.
struct ProductListView: View {
    var body: some View {
        List(Constants.placeholderIDs, id: \.self) { id in
            NavigationLink(value: Route.product(id)) {
                Text(verbatim: String(id.uuidString.prefix(Constants.idPrefixLength)))
                    .textStyle(.body)
                    .foregroundStyle(.foregroundPrimary)
            }
        }
        .navigationTitle("Products")
    }
}

extension ProductListView {
    fileprivate enum Constants {
        /// Fixed ids so the rows and the details screen agree across launches and previews.
        static let placeholderIDs: [Product.ID] = [
            UUID(uuidString: "00000000-0000-0000-0000-000000000001"),
            UUID(uuidString: "00000000-0000-0000-0000-000000000002"),
            UUID(uuidString: "00000000-0000-0000-0000-000000000003"),
        ].compactMap(\.self)

        /// How much of a UUID a row shows; enough to tell the rows apart.
        static let idPrefixLength = 8
    }
}

#Preview {
    NavigationStack {
        ProductListView()
    }
}
