import Combine
import Foundation

extension Publisher {
    /// Every value the publisher emits before completing, or the failure that ended it. Tests assert on this so a
    /// publisher that emits twice is caught as well as one with the wrong value. A publisher that never completes
    /// hangs here; suites using it carry a time limit.
    func emissions() async -> Result<[Output], Failure> {
        do {
            var collected: [Output] = []
            for try await values in collect().values {
                collected = values
            }
            return .success(collected)
        } catch let failure as Failure {
            return .failure(failure)
        } catch {
            preconditionFailure("A publisher cannot fail with a foreign error: \(error)")
        }
    }
}
