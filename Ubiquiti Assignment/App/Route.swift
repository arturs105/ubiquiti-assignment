import Foundation

/// A screen the root navigation stack can push, as a value the stack's path holds.
///
/// Carries the product itself: the list already holds everything the details show, so the screen opens on the
/// value tapped and loads nothing but its image. See `docs/DECISIONS.md`, 2026-10-20 "Route by value".
nonisolated enum Route: Hashable, Sendable {
    case product(Product)
}
