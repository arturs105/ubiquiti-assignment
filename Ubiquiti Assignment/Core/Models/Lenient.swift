import Foundation

/// Decodes one array element without failing the array: a broken element becomes `.failed` instead of an error.
nonisolated enum Lenient<Wrapped: Decodable>: Decodable {
    case decoded(Wrapped)
    case failed(any Error)

    init(from decoder: any Decoder) {
        do {
            self = try .decoded(Wrapped(from: decoder))
        } catch {
            self = .failed(error)
        }
    }
}
