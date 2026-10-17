import Foundation

/// Reading a repository's `updates()` stream in a test without closures, which `#expect` cannot send across
/// isolation.
extension AsyncStream where Element: Sendable {
    /// The first element, or `nil` when the stream ends before one arrives.
    func firstElement() async -> Element? {
        for await element in self {
            return element
        }
        return nil
    }

    /// Every element until the stream ends, in order. Only finishes once the producer is gone.
    func collect() async -> [Element] {
        var elements: [Element] = []
        for await element in self {
            elements.append(element)
        }
        return elements
    }
}
