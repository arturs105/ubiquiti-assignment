import Foundation

/// A failure as a screen shows it: a headline, one line saying what the user can do, and a symbol.
///
/// The one shape every error state renders, whichever Core error produced it (`FeedError`, `ImageError`), so a view
/// never switches over transport codes or shows a description written for a log. The mappings live in the
/// `DisplayError+<Error>` extensions and are the fixed values below, so a test can name the one it expects. Every
/// failure the app can show is retryable, so there is no retry flag: the view that owns the retry action shows the
/// button. See `docs/DECISIONS.md`, 2026-10-20 "`DisplayError`: five failures the user can act on".
nonisolated struct DisplayError: Equatable, Sendable {
    /// Short headline, such as "You’re offline".
    let title: LocalizedStringResource
    /// One sentence on what happened and what to do about it.
    let message: LocalizedStringResource
    /// SF Symbol shown with the headline.
    let systemImage: String

    /// The device has no route to the internet: airplane mode, no signal, cellular data off.
    static let offline = DisplayError(
        title: "You’re offline",
        message: "Check your internet connection and try again.",
        systemImage: "wifi.slash",
    )

    /// The request left the device but never got an answer: timeout, DNS, TLS, a connection dropped mid-request.
    static let unreachable = DisplayError(
        title: "Couldn’t reach the server",
        message: "The connection failed. Check your network and try again.",
        systemImage: "wifi.exclamationmark",
    )

    /// The server answered, but not with what was asked for: an error status or a response that is not HTTP.
    static let serverUnavailable = DisplayError(
        title: "Server unavailable",
        message: "The server isn’t answering as expected. Try again in a moment.",
        systemImage: "exclamationmark.icloud",
    )

    /// The feed arrived but does not decode.
    static let unreadableFeed = DisplayError(
        title: "Couldn’t read the product list",
        message: "The server sent data the app doesn’t understand. Try again later.",
        systemImage: "doc.questionmark",
    )

    /// The image server refused the request with an error status, or the image arrived, or sat in the cache, but no
    /// picture could be made of it.
    static let unavailableImage = DisplayError(
        title: "Image unavailable",
        message: "The image couldn’t be shown.",
        systemImage: "photo.badge.exclamationmark",
    )
}
