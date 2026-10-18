import Foundation
@testable import Ubiquiti_Assignment

/// What one load produced: the cached feed, if any, and how the refresh ended.
struct FeedLoad: Equatable {
    let cached: Feed?
    let refresh: Result<FeedRefresh, FeedError>
}
