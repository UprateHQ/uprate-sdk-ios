import Foundation

public struct ReviewSignalResult: Decodable, Sendable {
    public let id: String
    public let status: String
    public let expiresAt: Date

    private enum CodingKeys: String, CodingKey {
        case id = "uuid"
        case status, expiresAt
    }
}

struct ReviewSignalRequestBody: Encodable, Sendable {
    let triggeredAt: String
    let metadata: ReviewSignalMetadataEnvelope

    private enum CodingKeys: String, CodingKey {
        case triggeredAt = "triggered_at"
        case metadata
    }
}

struct ReviewSignalMetadataEnvelope: Encodable, Sendable {
    let device: DeviceMetadata
}
