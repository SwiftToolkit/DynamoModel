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

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.