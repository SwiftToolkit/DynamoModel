import Foundation

@dynamicMemberLookup
public struct DynamoModelOf<T: Codable & DynamoModel & Sendable>: Codable, Sendable {
    public private(set) var base: T

    public init(_ base: T) {
        self.base = base
    }

    public init(base: T) {
        self.base = base
    }

    public subscript<Property>(dynamicMember keyPath: KeyPath<T, Property>) -> Property {
        base[keyPath: keyPath]
    }

    public subscript<Property>(dynamicMember keyPath: WritableKeyPath<T, Property>) -> Property {
        get { base[keyPath: keyPath] }
        set { base[keyPath: keyPath] = newValue }
    }

    public init(from decoder: any Decoder) throws {
        let valueContainer = try decoder.singleValueContainer()
        base = try valueContainer.decode(T.self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: AnyCodingKey.self)

        // Create a temporary encoder to capture the base object's encoded key-value pairs
        let tempEncoder = DictionaryEncoder()
        try base.encode(to: tempEncoder)

        // Encode each property from the encoded dictionary to our container
        for (key, value) in tempEncoder.storage {
            // Skip partition and sort keys as they'll be handled separately
            if key == T.partitionKeyName || key == T.sortKeyName {
                continue
            }
            if let encodableValue = value as? Encodable {
                try container.encode(encodableValue, forKey: .init(stringValue: key)!)
            }
        }

        // Encode the partition and sort keys
        try container.encode(base.partitionKey, forKey: .init(stringValue: T.partitionKeyName)!)

        if let sortKey = base.sortKey {
            if let sortKeyName = T.sortKeyName {
                try container.encode(sortKey, forKey: .init(stringValue: sortKeyName)!)
            } else {
                throw EncodingError.invalidValue(sortKey, .init(
                    codingPath: [],
                    debugDescription: "Sort key present but no sort key name defined"
                ))
            }
        }
    }
}
