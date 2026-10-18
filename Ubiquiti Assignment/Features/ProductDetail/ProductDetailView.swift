import SwiftUI

/// Placeholder for the product details: shows the id the route carried.
///
/// Exists so the shell's navigation runs end to end. The real screen subscribes to the repository's feed through its
/// view model and looks the product up by this id.
struct ProductDetailView: View {
    private let productID: Product.ID

    /// - Parameter productID: the product the route asked for.
    init(productID: Product.ID) {
        self.productID = productID
    }

    // MARK: - View

    var body: some View {
        VStack(spacing: Spacing.small) {
            Text("Product details")
                .textStyle(.bodyBold)
                .foregroundStyle(.foregroundPrimary)
            Text(productID.uuidString)
                .textStyle(.caption)
                .foregroundStyle(.foregroundSecondary)
        }
        .padding(Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.backgroundSecondary)
        .navigationTitle("Details")
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(productID: UUID())
    }
}
