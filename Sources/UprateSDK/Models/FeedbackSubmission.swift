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
    public let replies: [FeedbackReply]

    private enum CodingKeys: String, CodingKey {
        case id = "uuid"
        case rating, message, sentiment, createdAt, replies
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        rating = try container.decodeIfPresent(Int.self, forKey: .rating)
        message = try container.decode(String.self, forKey: .message)
        sentiment = try container.decodeIfPresent(String.self, forKey: .sentiment)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        replies = try container.decodeIfPresent([FeedbackReply].self, forKey: .replies) ?? []
    }
}

public struct FeedbackReply: Identifiable, Decodable, Sendable {
    public let id: String
    public let feedbackId: String
    public let body: String
    public let createdAt: Date
    public let readAt: Date?

    private enum CodingKeys: String, CodingKey {
        case id = "uuid"
        case feedbackId = "feedbackUuid"
        case body, createdAt, readAt
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

struct FeedbackRepliesResponse: Decodable, Sendable {
    let replies: [FeedbackReply]
}

struct ReadRepliesRequestBody: Encodable, Sendable {
    let uuids: [String]
}
