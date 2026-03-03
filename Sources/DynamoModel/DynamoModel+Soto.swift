//
//  DynamoDB+DynamoModel.swift
//  DynamoModel
//
//  Created by Natan Rolnik on 03-03-2026.
//

#if SotoDynamoDB

import SotoDynamoDB

// MARK: - DynamoKey → AttributeValue

public extension DynamoKey {
    /// Converts a `DynamoKey` to a `DynamoDB.AttributeValue`.
    var attributeValue: DynamoDB.AttributeValue {
        switch self {
        case let string as String:
            .s(string)
        case let int as Int:
            .n(String(int))
        case let bool as Bool:
            .bool(bool)
        default:
            fatalError("Unsupported DynamoKey type: \(type(of: self))")
        }
    }
}

// MARK: - DynamoModel Key Dictionaries

public extension DynamoModel {
    /// Builds a key dictionary from this instance's partition and sort keys.
    func keyDictionary() -> [String: DynamoDB.AttributeValue] {
        var dict: [String: DynamoDB.AttributeValue] = [
            Self.partitionKeyName: partitionKey.attributeValue,
        ]
        if let sortKey, let sortKeyName = Self.sortKeyName {
            dict[sortKeyName] = sortKey.attributeValue
        }
        return dict
    }

    /// Builds a key dictionary from raw key values (for get/delete without a full instance).
    static func keyDictionary(
        partitionKey: DynamoKey,
        sortKey: DynamoKey? = nil
    ) -> [String: DynamoDB.AttributeValue] {
        var dict: [String: DynamoDB.AttributeValue] = [
            partitionKeyName: partitionKey.attributeValue,
        ]
        if let sortKey, let sortKeyName {
            dict[sortKeyName] = sortKey.attributeValue
        }
        return dict
    }
}

// MARK: - DynamoDB CRUD Extensions

public extension DynamoDB {
    // MARK: Put

    /// Puts an item into DynamoDB, wrapping it in `DynamoModelOf` for proper key encoding.
    @discardableResult
    func put<T: DynamoModel & Codable & Sendable>(
        _ item: T,
        tableName: String,
        logger: Logger = AWSClient.loggingDisabled
    ) async throws -> T {
        let input = PutItemCodableInput(
            item: DynamoModelOf(item),
            tableName: tableName
        )
        _ = try await putItem(input, logger: logger)
        return item
    }

    // MARK: Get

    /// Gets a single item by its primary key.
    func get<T: DynamoModel & Codable & Sendable>(
        _: T.Type,
        partitionKey: DynamoKey,
        sortKey: DynamoKey? = nil,
        tableName: String,
        logger: Logger = AWSClient.loggingDisabled
    ) async throws -> T? {
        let input = GetItemInput(
            key: T.keyDictionary(partitionKey: partitionKey, sortKey: sortKey),
            tableName: tableName
        )
        let output = try await getItem(input, type: DynamoModelOf<T>.self, logger: logger)
        return output.item?.base
    }

    // MARK: Delete

    /// Deletes an item by its primary key values.
    func delete<T: DynamoModel & Codable & Sendable>(
        _: T.Type,
        partitionKey: DynamoKey,
        sortKey: DynamoKey? = nil,
        tableName: String,
        logger: Logger = AWSClient.loggingDisabled
    ) async throws {
        let input = DeleteItemInput(
            key: T.keyDictionary(partitionKey: partitionKey, sortKey: sortKey),
            tableName: tableName
        )
        _ = try await deleteItem(input, logger: logger)
    }

    /// Deletes an item using its instance keys.
    func delete<T: DynamoModel & Codable & Sendable>(
        _ item: T,
        tableName: String,
        logger: Logger = AWSClient.loggingDisabled
    ) async throws {
        let input = DeleteItemInput(
            key: item.keyDictionary(),
            tableName: tableName
        )
        _ = try await deleteItem(input, logger: logger)
    }

    // MARK: Query

    /// Executes a single-page query and returns decoded items.
    func query<T: DynamoModel & Codable & Sendable>(
        _: T.Type,
        input: QueryInput,
        logger: Logger = AWSClient.loggingDisabled
    ) async throws -> [T] {
        let output = try await query(input, type: DynamoModelOf<T>.self, logger: logger)
        return output.items?.map(\.base) ?? []
    }

    /// Executes a paginated query collecting all pages and returning decoded items.
    func queryAll<T: DynamoModel & Codable & Sendable>(
        _: T.Type,
        input: QueryInput,
        logger: Logger = AWSClient.loggingDisabled
    ) async throws -> [T] {
        let paginator = queryPaginator(input, type: DynamoModelOf<T>.self, logger: logger)
        var results: [T] = []
        for try await page in paginator {
            if let items = page.items {
                results.append(contentsOf: items.map(\.base))
            }
        }
        return results
    }

    // MARK: Batch Delete

    /// Deletes items in batches of 25 (DynamoDB's batch limit).
    func batchDelete<T: DynamoModel & Codable & Sendable>(
        _ items: [T],
        tableName: String,
        logger: Logger = AWSClient.loggingDisabled
    ) async throws {
        for chunk in items.chunked(into: 25) {
            let writeRequests = chunk.map { item in
                WriteRequest(deleteRequest: DeleteRequest(key: item.keyDictionary()))
            }
            let input = BatchWriteItemInput(requestItems: [tableName: writeRequests])
            _ = try await batchWriteItem(input, logger: logger)
        }
    }

    // MARK: Batch Put

    /// Puts items in batches of 25 (DynamoDB's batch limit).
    func batchPut<T: DynamoModel & Codable & Sendable>(
        _ items: [T],
        tableName: String,
        encoder: DynamoDBEncoder = DynamoDBEncoder(),
        logger: Logger = AWSClient.loggingDisabled
    ) async throws {
        for chunk in items.chunked(into: 25) {
            let writeRequests = try chunk.map { item in
                let encoded = try encoder.encode(DynamoModelOf(item))
                return WriteRequest(putRequest: PutRequest(item: encoded))
            }
            let input = BatchWriteItemInput(requestItems: [tableName: writeRequests])
            _ = try await batchWriteItem(input, logger: logger)
        }
    }
}

// MARK: - Array Chunking

extension Array {
    /// Splits the array into chunks of the given size.
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

#endif
