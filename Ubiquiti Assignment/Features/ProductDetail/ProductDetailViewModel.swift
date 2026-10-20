import Foundation

/// The product details: the product the list handed over, and the slot for its hero image.
///
/// Nothing here loads or derives: the feed carries every attribute the screen shows, so the product arrives
/// complete on the route and the hero image is the only thing fetched, through its own view model. See
/// `docs/DECISIONS.md`, 2026-10-20 "Route by value".
@Observable
final class ProductDetailViewModel {
    let product: Product
    let hero: ProductImageViewModel

    init(product: Product, imageLoader: any ImageLoader) {
        self.product = product
        hero = ProductImageViewModel(product: product, size: .hero, loader: imageLoader)
    }
}
