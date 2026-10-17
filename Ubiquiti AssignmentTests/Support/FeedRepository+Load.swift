import Foundation
@testable import Ubiquiti_Assignment

extension FeedRepository {
    /// One load as the view model runs it: the cached snapshot when there is one, then the refresh. Collected into
    /// a list so a test asserts order and count in one expression, or the failure that ended the load.
    func load() async -> Result<[FeedSnapshot], FeedError> {
        var snapshots: [FeedSnapshot] = []
        if let cached = await cachedSnapshot() {
            snapshots.append(cached)
        }
        do {
            try await snapshots.append(refresh())
        } catch {
            return .failure(error)
        }
        return .success(snapshots)
    }
}
