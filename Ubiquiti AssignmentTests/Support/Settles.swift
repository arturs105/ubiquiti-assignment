import Foundation
@testable import Ubiquiti_Assignment

/// Whether the view model reaches `expected` before the deadline. The feed stream is iterated by a task of its own,
/// so a state that follows a refresh lands a hop after the refresh returns; polling keeps the test free of timing
/// assumptions beyond the deadline.
@MainActor
func settles(
    _ viewModel: ProductListViewModel,
    at expected: LoadState<[Product]>,
    within timeout: Duration = Settling.deadline,
) async -> Bool {
    await settles(viewModel, within: timeout) { $0.state == expected }
}

/// Whether the view model satisfies `condition` before the deadline. For an end state that spans more than `state`:
/// the feed task and the refresh task each send into their own subject, in an order the scheduler picks, so a state
/// can land before or after `isRefreshing` clears.
///
/// Each check is followed by a sleep, not a `Task.yield()`: a yield re-enqueues at once and keeps the main thread
/// busy, which on a loaded CI runner starved the repository actor the feed task was waiting on past the deadline.
@MainActor
func settles(
    _ viewModel: ProductListViewModel,
    within timeout: Duration = Settling.deadline,
    until condition: (ProductListViewModel) -> Bool,
) async -> Bool {
    let deadline = ContinuousClock.now + timeout
    while !condition(viewModel) {
        guard ContinuousClock.now < deadline else { return false }
        try? await Task.sleep(for: Settling.interval)
    }
    return true
}

enum Settling {
    /// How long a test waits for the view model before giving up. Generous because a parallel test run on a CI
    /// runner can stall for seconds; a passing test never waits it out.
    static let deadline: Duration = .seconds(10)
    /// The pause between two checks: short enough to add nothing noticeable to a test, long enough to leave the
    /// main thread idle between checks.
    static let interval: Duration = .milliseconds(10)
}
