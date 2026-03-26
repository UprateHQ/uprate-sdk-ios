import Foundation

// MARK: - Public Models

public struct FeedbackResult: Decodable, Sendable {
    public let id: String
    public let rating: Int?
    public let message: String
    public let status: String
    public let createdAt: Date

    private enum CodingKeys: String, CodingKey {
        case id = "uuid"
        case rating, message, status, createdAt
    }
}

public struct FeedbackSubmission: Identifiable, Decodable, Sendable {
    public let id: String
    public let rating: Int?
    public let message: String
    public let sentiment: String?
    public let createdAt: Date

    private enum CodingKeys: String, CodingKey {
        case id = "uuid"
        case rating, message, sentiment, createdAt
    }
}

// MARK: - Internal Types

struct FeedbackRequestBody: Encodable, Sendable {
    let message: String
    let rating: Int?
    let metadata: FeedbackMetadataEnvelope?
}

struct FeedbackMetadataEnvelope: Encodable, Sendable {
    let device: DeviceMetadata?
    let custom: [String: AnyCodable]?
}

struct FeedbackListResponse: Decodable, Sendable {
    let feedback: [FeedbackSubmission]
}
