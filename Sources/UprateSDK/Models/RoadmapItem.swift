import Foundation

public struct UprateRoadmapResponse: Decodable, Sendable {
    public let settings: RoadmapSettings
    public let items: [RoadmapItem]
}

public struct RoadmapSettings: Decodable, Sendable {
    public let votingEnabled: Bool
    public let showVoteCount: Bool
    public let votingExcludedStatuses: [String]
}

public struct RoadmapItem: Identifiable, Decodable, Sendable {
    public let id: String
    public let title: String
    public let description: String?
    public let status: String
    public let statusLabel: String
    public let votesCount: Int?
    public let hasVoted: Bool
    public let votingDisabled: Bool

    private enum CodingKeys: String, CodingKey {
        case id = "uuid"
        case title, description, status, statusLabel, votesCount
        case hasVoted, votingDisabled
    }
}
