public struct VoteResult: Decodable, Sendable {
    public let voted: Bool
    public let votesCount: Int
}
