# DynamoModel

A tiny, dependency-free Swift library for helping you work with single-table design in DynamoDB.

## Motivation

To read more about the motivation behind this package, check out the blog post on SwiftToolkit.dev: [Writing Single-Table DynamoDB Apps with DynamoModel](https://www.swifttoolkit.dev/posts/dynamo-model/).

## Overview

DynamoModel provides a simple protocol-based approach to modeling your data for DynamoDB's single-table design pattern. It helps you manage partition keys and sort keys in a type-safe way, while keeping your models clean and focused on business logic.

## Usage

### Basic Example

```swift
import DynamoModel
import Foundation

struct User: Codable {
    let id: UUID
    let name: String
    let email: String
    let verified: Bool
}

extension User: DynamoModel {
    var partitionKey: DynamoKey { "USER#\(id.uuidString)" }
    var sortKey: DynamoKey? { "PROFILE" }
}
```

### Key Concepts

**Partition Key (`pk`)**: The primary identifier for your item. By default, DynamoModel uses `"pk"` as the attribute name.

**Sort Key (`sk`)**: Optional secondary identifier for sorting and querying. By default, uses `"sk"` as the attribute name.

Both keys are automatically included when encoding your model to JSON:

```swift
let user = User(
    id: UUID(uuidString: "123E4567-E89B-12D3-A456-426614174000")!,
    name: "John Doe",
    email: "john.doe@example.com",
    points: 100,
    verified: true
)

let data = try JSONEncoder().encode(user)
// Results in:
// {
//     "pk": "USER#123E4567-E89B-12D3-A456-426614174000",
//     "sk": "PROFILE",
//     "id": "123E4567-E89B-12D3-A456-426614174000",
//     "name": "John Doe",
//     "email": "john.doe@example.com",
//     "points": 100,
//     "verified": true
// }
```

### Custom Key Names

If you need different attribute names for your keys in your table, override the static properties:

```swift
struct UserFollower: Codable {
    let followerId: UUID
    let followedId: UUID
    let followedAt: Date
}

extension Follower: DynamoModel {
    var partitionKey: DynamoKey { "USER#\(followerId.uuidString)" }
    var sortKey: DynamoKey? { "FOLLOWS#\(followedId.uuidString)" }
    
    static var partitionKeyName: String { "customPK" }
    static var sortKeyName: String? { "customSK" }
}
```

### Using DynamoModelOf

`DynamoModelOf` is a wrapper that allows you to use your model as a dictionary of properties.

```swift
let user = User(
    id: UUID(),
    name: "John Doe",
    email: "john.doe@example.com",
    verified: false
)
let dynamoUser = DynamoModelOf(user)
let data = try JSONEncoder().encode(dynamoUser)
```

Because `DynamoModelOf` uses the `@dynamicMemberLookup` protocol, you can access the properties of the model using the dot syntax instead of having to go through the base model properties.

```swift
let name = dynamoUser.name // instead of dynamoUser.base.name
let email = dynamoUser.email // instead of dynamoUser.base.email
```

## SotoDynamoDB CRUD Helpers (Package Trait)

DynamoModel includes an opt-in **Package Trait** (`SotoDynamoDB`) that adds convenience CRUD methods as extensions on Soto's `DynamoDB` client. When enabled, Soto is resolved as a dependency and you get one-liner methods for common operations — no more boilerplate.

### Enabling the Trait

In your `Package.swift`, pass the trait when declaring the dependency:

```swift
.package(
    url: "https://github.com/user/DynamoModel.git",
    from: "1.0.0",
    traits: ["SotoDynamoDB"]
)
```

> **Note:** When the trait is not enabled, DynamoModel remains zero-dependency. Soto is never fetched or resolved.

### Available Methods

All methods are extensions on `DynamoDB` with the generic constraint `T: DynamoModel & Codable & Sendable`.

```swift
// Put
try await dynamodb.put(user, tableName: "my-table")

// Get
let user = try await dynamodb.get(User.self, partitionKey: "USER#123", sortKey: "PROFILE", tableName: "my-table")

// Delete by key
try await dynamodb.delete(User.self, partitionKey: "USER#123", sortKey: "PROFILE", tableName: "my-table")

// Delete by instance
try await dynamodb.delete(user, tableName: "my-table")

// Query (single page)
let users = try await dynamodb.query(User.self, input: queryInput)

// Query (all pages)
let allUsers = try await dynamodb.queryAll(User.self, input: queryInput)

// Batch put (auto-chunks into groups of 25)
try await dynamodb.batchPut(users, tableName: "my-table")

// Batch delete (auto-chunks into groups of 25)
try await dynamodb.batchDelete(users, tableName: "my-table")
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.