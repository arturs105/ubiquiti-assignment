import Foundation

/// A screen the root navigation stack can push, as a value the stack's path holds.
///
/// Carries the product's id, not the product: the details screen looks the product up in the repository's `feed()`
/// stream, so a refresh while details are open updates them too. See `docs/DECISIONS.md`, 2026-10-18 "Route by ID".
enum Route: Hashable, Sendable {
    /// The details of one product.
    case product(Product.ID)
}
