public protocol RoadmapProviding: Sendable {
    func getItems() async throws -> UprateRoadmapResponse
    func vote(itemId: String) async throws -> VoteResult
    func removeVote(itemId: String) async throws -> VoteResult
    func submitRequest(title: String, description: String?) async throws -> FeatureRequest
    func getMyRequests() async throws -> [FeatureRequest]
}
