import Foundation
import Testing
import UIKit
@testable import Ubiquiti_Assignment

/// A class, not a struct, so `deinit` can remove each test's cache directory once the test is over.
@Suite(.timeLimit(.minutes(1)))
final class KingfisherImageLoaderTests {
    private let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
    private let png = UIImage.solid(.red, size: .thumbnail).pngData() ?? Data()

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    @Test func downloadedBytesComeBackAsAnImage() async throws {
        let product = try Product.stub()
        StubURLProtocol.script(.http(status: 200, body: png), at: product.imageURL(size: .thumbnail))

        let image = try await loader().image(for: product, size: .thumbnail)

        #expect(image.size == CGSize(width: ImageSize.thumbnail.pixelWidth, height: ImageSize.thumbnail.pixelWidth))
    }

    @Test func secondLoadOfTheSameImageDoesNotTouchTheNetwork() async throws {
        let product = try Product.stub()
        let url = product.imageURL(size: .thumbnail)
        StubURLProtocol.script(.http(status: 200, body: png), at: url)
        let loader = try loader()

        _ = try await loader.image(for: product, size: .thumbnail)
        _ = try await loader.image(for: product, size: .thumbnail)

        #expect(StubURLProtocol.requestCount(for: url) == 1)
    }

    @Test func eachSizeIsItsOwnDownload() async throws {
        let product = try Product.stub()
        StubURLProtocol.script(.http(status: 200, body: png), at: product.imageURL(size: .thumbnail))
        StubURLProtocol.script(.http(status: 200, body: png), at: product.imageURL(size: .hero))
        let loader = try loader()

        _ = try await loader.image(for: product, size: .thumbnail)
        _ = try await loader.image(for: product, size: .hero)

        #expect(StubURLProtocol.requestCount(for: product.imageURL(size: .thumbnail)) == 1)
        #expect(StubURLProtocol.requestCount(for: product.imageURL(size: .hero)) == 1)
    }

    @Test func aNewLoaderOverTheSameDirectoryServesTheImageFromDisk() async throws {
        let product = try Product.stub()
        let url = product.imageURL(size: .thumbnail)
        StubURLProtocol.script(.http(status: 200, body: png), at: url)
        _ = try await loader().image(for: product, size: .thumbnail)
        // Kingfisher writes the file off the calling queue; wait for it rather than for a fixed time.
        try await waitForCacheFile()

        _ = try await loader().image(for: product, size: .thumbnail)

        #expect(StubURLProtocol.requestCount(for: url) == 1)
    }

    @Test func httpErrorStatusIsReportedAsANetworkError() async throws {
        let product = try Product.stub()
        StubURLProtocol.script(.http(status: HTTPStatus.forbidden), at: product.imageURL(size: .thumbnail))

        await #expect(throws: ImageError.network(.httpStatus(HTTPStatus.forbidden))) {
            try await loader().image(for: product, size: .thumbnail)
        }
    }

    @Test func transportFailureIsReportedAsANetworkError() async throws {
        let product = try Product.stub()
        StubURLProtocol.script(.failure(URLError(.notConnectedToInternet)), at: product.imageURL(size: .thumbnail))

        let error = await #expect(throws: ImageError.self) {
            try await loader().image(for: product, size: .thumbnail)
        }

        guard case let .network(.network(urlError)) = error else {
            Issue.record("Expected a transport error, got \(String(describing: error))")
            return
        }
        #expect(urlError.code == .notConnectedToInternet)
    }

    @Test func bytesThatAreNotAnImageAreReportedAsInvalid() async throws {
        let product = try Product.stub()
        StubURLProtocol.script(.http(status: 200, body: Data("not a png".utf8)), at: product.imageURL(size: .thumbnail))

        await #expect(throws: ImageError.invalidImage) {
            try await loader().image(for: product, size: .thumbnail)
        }
    }

    @Test func cancellingTheAwaitingTaskReportsCancelled() async throws {
        let product = try Product.stub()
        StubURLProtocol.script(.hang, at: product.imageURL(size: .thumbnail))
        let loader = try loader()

        let task = Task {
            try await loader.image(for: product, size: .thumbnail)
        }
        // Cancel a download that is running, not a task that has not started: that path is a different error.
        try await waitForRequest(to: product.imageURL(size: .thumbnail))
        task.cancel()

        await #expect(throws: ImageError.cancelled) {
            try await task.value
        }
    }

    // MARK: - Helpers

    private func loader() throws -> KingfisherImageLoader {
        let configuration = URLSessionConfiguration.images()
        configuration.protocolClasses = [StubURLProtocol.self]
        return try KingfisherImageLoader(directory: directory, sessionConfiguration: configuration)
    }

    /// Polls until the stub has seen a request for `url`, bounded by the suite's time limit.
    private func waitForRequest(to url: URL) async throws {
        while StubURLProtocol.requestCount(for: url) == 0 {
            try await Task.sleep(for: Constants.pollInterval)
        }
    }

    /// Polls until a file appears under the cache directory, bounded by the suite's time limit.
    private func waitForCacheFile() async throws {
        while try FileManager.default.subpathsOfDirectory(atPath: directory.path())
            .contains(where: { $0.contains("/") }) == false
        {
            try await Task.sleep(for: Constants.pollInterval)
        }
    }
}

extension KingfisherImageLoaderTests {
    nonisolated enum Constants {
        static let pollInterval = Duration.milliseconds(20)
    }
}
