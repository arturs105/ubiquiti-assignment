import Observation
@testable import Ubiquiti_Assignment

/// Every value a view model's `state` takes from the moment the recorder starts, in order, so a test can assert a
/// state the screen never passes through. `settles` cannot: `Observations` coalesces changes made in one turn of the
/// main actor, and a flash of the loading view between two of them is exactly what such a test looks for.
///
/// `withObservationTracking` calls its `onChange` synchronously in the property's `willSet`, before the new value is
/// stored, so each call records the value being replaced and re-arms the tracking for the next change; the value
/// the property holds now closes the list.
@MainActor
final class StateRecorder {
    private let viewModel: ProductListViewModel
    private var replaced: [LoadState<[Product]>] = []

    init(_ viewModel: ProductListViewModel) {
        self.viewModel = viewModel
        track()
    }

    /// The state when recording started, then every value it has changed to since, the current one last.
    var states: [LoadState<[Product]>] {
        replaced + [viewModel.state]
    }

    private func track() {
        withObservationTracking {
            _ = viewModel.state
        } onChange: { [weak self] in
            // The view model assigns `state` from its Combine sink, on the main actor.
            MainActor.assumeIsolated {
                guard let self else { return }
                self.replaced.append(self.viewModel.state)
                self.track()
            }
        }
    }
}
