import Foundation

/// A `LocalizedError` that carries a fixed message, for previews of error states before `DisplayError` exists.
nonisolated struct PreviewError: LocalizedError {
    private let message: String

    init(message: String) {
        self.message = message
    }

    var errorDescription: String? {
        message
    }
}
