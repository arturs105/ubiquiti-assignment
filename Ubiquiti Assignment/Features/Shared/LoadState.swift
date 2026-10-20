import Foundation

/// What a screen has to show, as one value the view switches over exhaustively.
///
/// Loading, empty and error states are graded, so each is a case with a dedicated view behind it rather than a
/// flag beside the data. There is no `idle`: a screen's pipeline emits `loading` the moment it is wired, before
/// anything has been asked for, so a state before loading never exists. See `docs/DECISIONS.md`, 2026-10-18.
enum LoadState<Value: Equatable>: Equatable {
    /// Nothing to show yet, neither cached nor downloaded.
    case loading
    /// Something to show. Whether it is current or stale is a separate value beside it.
    case loaded(Value)
    /// The source answered with nothing to show.
    case empty
    /// Nothing to show and the last attempt failed, already worded for the screen. The state stays `failed` while
    /// a retry runs, so the error view shows the retry in place rather than giving way to the loading view.
    case failed(DisplayError)
}
