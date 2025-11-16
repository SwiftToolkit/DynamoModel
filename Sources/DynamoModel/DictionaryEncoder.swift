import Foundation

// Helper encoder that captures encoded key-value pairs
internal class DictionaryEncoder: Encoder {
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] = [:]
    var storage: [String: Any] = [:]

    func container<Key>(keyedBy _: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        KeyedEncodingContainer(DictionaryKeyedEncoder(encoder: self))
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("Unkeyed encoding not supported")
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError("Single value encoding not supported")
    }
}

private struct DictionaryKeyedEncoder<K: CodingKey>: KeyedEncodingContainerProtocol {
    var codingPath: [CodingKey] = []
    let encoder: DictionaryEncoder

    typealias Key = K

    mutating func encodeNil(forKey key: K) throws {
        encoder.storage[key.stringValue] = nil
    }

    mutating func encode(_ value: some Encodable, forKey key: K) throws {
        encoder.storage[key.stringValue] = value
    }

    mutating func nestedContainer<NestedKey>(keyedBy _: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        // For DynamoDB, we want to flatten the structure, so we'll reuse the same encoder
        // but update the coding path to reflect the nesting
        let nestedEncoder = DictionaryEncoder()
        nestedEncoder.codingPath = codingPath + [key]
        return KeyedEncodingContainer(DictionaryKeyedEncoder<NestedKey>(encoder: nestedEncoder))
    }

    mutating func nestedUnkeyedContainer(forKey _: K) -> any UnkeyedEncodingContainer {
        // Since DynamoDB doesn't support nested arrays directly, we'll throw
        fatalError("Nested unkeyed containers are not supported for DynamoDB encoding")
    }

    mutating func superEncoder() -> any Encoder {
        // Create a new encoder for super encoding
        let superEncoder = DictionaryEncoder()
        superEncoder.codingPath = codingPath
        return superEncoder
    }

    mutating func superEncoder(forKey key: K) -> any Encoder {
        // Create a new encoder for super encoding with the given key
        let superEncoder = DictionaryEncoder()
        superEncoder.codingPath = codingPath + [key]
        return superEncoder
    }
}

internal struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    /// String-based keys, for example in dictionaries
    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    // Int-based keys, for example in arrays, not relevant
    // for most use cases
    init?(intValue _: Int) {
        nil
    }
}
