import Foundation

/// Button titles used by more than one view, so each string is written once.
///
/// A shared title rather than a shared `RetryButton`: the error state shows a prominent bordered button with a
/// symbol and the stale-data banner a borderless caption, so only the wording is common.
enum ButtonTitle {
    /// Re-runs the request that failed, on the error state and the stale-data banner.
    static let retry: LocalizedStringResource = "Retry"
}
