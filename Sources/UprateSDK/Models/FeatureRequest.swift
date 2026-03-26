import Foundation

public struct FeatureRequest: Identifiable, Decodable, Sendable {
    public let id: String
    public let title: String
    public let description: String?
    public let status: String
    public let createdAt: Date

    private enum CodingKeys: String, CodingKey {
        case id = "uuid"
        case title, description, status, createdAt
    }
}

// MARK: - Internal

struct FeatureRequestListResponse: Decodable, Sendable {
    let requests: [FeatureRequest]
}

struct FeatureRequestBody: Encodable, Sendable {
    let title: String
    let description: String?
}
