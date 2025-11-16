import Foundation
import Testing
@testable import DynamoModel

struct User: DynamoModel, Codable, Sendable, Equatable {
    let id: UUID
    let name: String
    let email: String
    let points: Int
    let verified: Bool

    var partitionKey: DynamoKey { "USER#\(id.uuidString)" }
    var sortKey: DynamoKey? { "PROFILE" }
}

let userJson = """
{
    "pk": "USER#123A4567-E89B-12D3-A456-426614174000",
    "sk": "PROFILE",
    "id": "123E4567-E89B-12D3-A456-426614174000",
    "name": "John Doe",
    "email": "john.doe@example.com",
    "points": 100,
    "verified": true
}
"""

let user = User(
    id: UUID(uuidString: "123E4567-E89B-12D3-A456-426614174000")!,
    name: "John Doe",
    email: "john.doe@example.com",
    points: 100,
    verified: true
)

@Test func testDecoding() async throws {
    let data = userJson.data(using: .utf8) ?? Data()
    let decodedUser = try JSONDecoder().decode(User.self, from: data)
    #expect(decodedUser == user)
    #expect((decodedUser.partitionKey as? String) == (user.partitionKey as? String))
}

@Test func testEncoding() async throws {
    let data = try JSONEncoder().encode(user)
    let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    let stringToJSON = try JSONSerialization.jsonObject(with: userJson.data(using: .utf8)!) as? [String: Any]

    for (key, value) in jsonObject ?? [:] {
        if let stringValue = value as? String {
            #expect(stringValue == stringToJSON?[key] as? String)
        } else if let intValue = value as? Int {
            #expect(intValue == stringToJSON?[key] as? Int)
        } else if let boolValue = value as? Bool {
            #expect(boolValue == stringToJSON?[key] as? Bool)
        } else {
            Issue.record("Unexpected value type: \(type(of: value))")
        }
    }
}
