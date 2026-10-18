import Foundation
@testable import Ubiquiti_Assignment

/// Whether the view model reaches `expected` before the deadline. The feed stream is iterated by a task of its own,
/// so a state that follows a refresh lands a hop after the refresh returns; polling keeps the test free of timing
/// assumptions beyond the deadline.
@MainActor
func settles(
    _ viewModel: ProductListViewModel,
    at expected: LoadState<[Product]>,
    within timeout: Duration = .seconds(2),
) async -> Bool {
    let deadline = ContinuousClock.now + timeout
    while viewModel.state != expected {
        guard ContinuousClock.now < deadline else { return false }
        await Task.yield()
    }
    return true
}
