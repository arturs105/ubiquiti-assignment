import Foundation

extension KeyedDecodingContainer {
    /// A nested keyed container, or nil when the key is absent or null, so optional feed blocks read in one line.
    nonisolated func decodeNestedContainerIfPresent<NestedKey: CodingKey>(
        keyedBy type: NestedKey.Type,
        forKey key: Key,
    ) throws -> KeyedDecodingContainer<NestedKey>? {
        guard contains(key), try decodeNil(forKey: key) == false else { return nil }
        return try nestedContainer(keyedBy: type, forKey: key)
    }
}
