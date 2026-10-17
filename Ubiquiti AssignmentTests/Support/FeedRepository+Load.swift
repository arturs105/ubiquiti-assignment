import Foundation
@testable import Ubiquiti_Assignment

/// What one load produced: the cached feed, if any, and how the refresh ended.
struct FeedLoad: Equatable {
    let cached: Feed?
    let refresh: Result<FeedRefresh, FeedError>
}

extension FeedRepository {
    /// One load as the view model runs it: the cached feed, then the refresh. Collected into one value so a test
    /// asserts both in one expression.
    func load() async -> FeedLoad {
        let cached = await cachedFeed()
        do {
            return try await FeedLoad(cached: cached, refresh: .success(refresh()))
        } catch {
            return FeedLoad(cached: cached, refresh: .failure(error))
        }
    }
}
