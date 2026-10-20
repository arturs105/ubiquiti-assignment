import Observation
@testable import Ubiquiti_Assignment

/// Whether the view model reaches `expected`. The feed stream is iterated by a task of its own, so a state that
/// follows a refresh lands a hop after the refresh returns; waiting on the view model's own observation keeps the
/// test free of timing assumptions altogether.
@MainActor
func settles(_ viewModel: ProductListViewModel, at expected: LoadState<[Product]>) async -> Bool {
    await settles(viewModel) { $0.state == expected }
}

/// Whether the view model comes to satisfy `condition`. For an end state that spans more than `state`: the feed
/// task and the refresh task each send into their own subject, in an order the scheduler picks, so a state can land
/// before or after `isRefreshing` clears.
///
/// `Observations` re-evaluates `condition` after every change to a property it read, so the wait neither polls nor
/// carries a deadline of its own: a passing test returns the moment the state lands, however long a stalled CI
/// runner held it (see `docs/DECISIONS.md`, 2026-10-19), and a failing one is cut off by the suite's time limit,
/// which cancels the test task and so ends the iteration.
@MainActor
func settles<ViewModel: AnyObject>(
    _ viewModel: ViewModel,
    until condition: @escaping @MainActor (ViewModel) -> Bool,
) async -> Bool {
    for await satisfied in Observations({ condition(viewModel) }) where satisfied {
        return true
    }
    return false
}
