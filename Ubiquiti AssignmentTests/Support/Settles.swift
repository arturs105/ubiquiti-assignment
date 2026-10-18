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
    await settles(viewModel, within: timeout) { $0.state == expected }
}

/// Whether the view model satisfies `condition` before the deadline. For an end state that spans more than `state`:
/// the feed task and the refresh task each send into their own subject, in an order the scheduler picks, so a state
/// can land before or after `isRefreshing` clears.
@MainActor
func settles(
    _ viewModel: ProductListViewModel,
    within timeout: Duration = .seconds(2),
    until condition: (ProductListViewModel) -> Bool,
) async -> Bool {
    let deadline = ContinuousClock.now + timeout
    while !condition(viewModel) {
        guard ContinuousClock.now < deadline else { return false }
        await Task.yield()
    }
    return true
}
