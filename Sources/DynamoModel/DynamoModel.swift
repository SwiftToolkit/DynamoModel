import Foundation

public protocol DynamoKey: Codable {}

extension String: DynamoKey {}
extension Int: DynamoKey {}
extension Bool: DynamoKey {}

public protocol DynamoModel {
    var partitionKey: DynamoKey { get }
    var sortKey: DynamoKey? { get }

    static var partitionKeyName: String { get }
    static var sortKeyName: String? { get }
}

public extension DynamoModel {
    static var partitionKeyName: String { "pk" }
    static var sortKeyName: String? { "sk" }
}
