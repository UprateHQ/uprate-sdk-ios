import Foundation

public struct UprateReviews: ReviewSignalProviding, Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func recordPrompt() async throws -> ReviewSignalResult {
        let formatter = ISO8601DateFormatter()
        let body = ReviewSignalRequestBody(
            triggeredAt: formatter.string(from: Date()),
            metadata: ReviewSignalMetadataEnvelope(
                device: DeviceMetadata.collect()
            )
        )
        return try await apiClient.execute(
            .recordReviewSignal(body: body),
            as: ReviewSignalResult.self
        )
    }
}

// MARK: - Endpoint Definitions

extension APIEndpoint {
    static func recordReviewSignal(body: ReviewSignalRequestBody) -> APIEndpoint {
        APIEndpoint(method: .post, path: "review-signals", body: body)
    }
}
