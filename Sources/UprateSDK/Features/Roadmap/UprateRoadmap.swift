import Foundation

public struct UprateRoadmap: RoadmapProviding, Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func getItems() async throws -> UprateRoadmapResponse {
        try await apiClient.execute(.roadmapItems, as: UprateRoadmapResponse.self)
    }

    public func vote(itemId: String) async throws -> VoteResult {
        try await apiClient.execute(.vote(itemId: itemId), as: VoteResult.self)
    }

    public func removeVote(itemId: String) async throws -> VoteResult {
        try await apiClient.execute(.removeVote(itemId: itemId), as: VoteResult.self)
    }

    public func submitRequest(title: String, description: String? = nil) async throws -> FeatureRequest {
        try await apiClient.execute(
            .submitFeatureRequest(title: title, description: description),
            as: FeatureRequest.self
        )
    }

    public func getMyRequests() async throws -> [FeatureRequest] {
        let response = try await apiClient.execute(.myRequests, as: FeatureRequestListResponse.self)
        return response.requests
    }
}

// MARK: - Endpoint Definitions

extension APIEndpoint {
    static let roadmapItems = APIEndpoint(method: .get, path: "roadmap")

    static func vote(itemId: String) -> APIEndpoint {
        APIEndpoint(method: .post, path: "roadmap/items/\(itemId)/vote")
    }

    static func removeVote(itemId: String) -> APIEndpoint {
        APIEndpoint(method: .delete, path: "roadmap/items/\(itemId)/vote")
    }

    static func submitFeatureRequest(title: String, description: String?) -> APIEndpoint {
        APIEndpoint(method: .post, path: "roadmap/requests", body: FeatureRequestBody(title: title, description: description))
    }

    static let myRequests = APIEndpoint(method: .get, path: "roadmap/requests")
}
