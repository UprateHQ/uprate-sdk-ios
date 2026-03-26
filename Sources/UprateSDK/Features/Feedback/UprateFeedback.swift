import Foundation

public final class UprateFeedback: FeedbackProviding, @unchecked Sendable {
    private let apiClient: APIClient
    private let _lock = NSLock()
    private var _collectDeviceMetadataValue: Bool = true

    /// Controls whether device metadata is auto-collected with feedback submissions.
    /// Default: `true`. Set to `false` to omit device info.
    public var collectDeviceMetadata: Bool {
        get { _lock.withLock { _collectDeviceMetadataValue } }
        set { _lock.withLock { _collectDeviceMetadataValue = newValue } }
    }

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func submit(
        message: String,
        rating: Int? = nil,
        metadata: [String: Any]? = nil
    ) async throws -> FeedbackResult {
        guard !message.isEmpty else {
            throw UprateError.validationError(
                message: "The message field is required.",
                errors: ["message": ["The message field is required."]]
            )
        }
        guard message.count <= 5000 else {
            throw UprateError.validationError(
                message: "The message field must not be greater than 5000 characters.",
                errors: ["message": ["The message field must not be greater than 5000 characters."]]
            )
        }
        if let rating {
            guard (1...5).contains(rating) else {
                throw UprateError.validationError(
                    message: "The rating field must be between 1 and 5.",
                    errors: ["rating": ["The rating field must be between 1 and 5."]]
                )
            }
        }

        let deviceMeta = collectDeviceMetadata ? DeviceMetadata.collect() : nil
        let customMeta = metadata?.mapValues { AnyCodable($0) }

        let envelope: FeedbackMetadataEnvelope? = (deviceMeta != nil || customMeta != nil)
            ? FeedbackMetadataEnvelope(device: deviceMeta, custom: customMeta)
            : nil

        let body = FeedbackRequestBody(
            message: message,
            rating: rating,
            metadata: envelope
        )

        return try await apiClient.execute(
            .submitFeedback(body: body),
            as: FeedbackResult.self
        )
    }

    public func getMySubmissions() async throws -> [FeedbackSubmission] {
        let response = try await apiClient.execute(.myFeedback, as: FeedbackListResponse.self)
        return response.feedback
    }
}

// MARK: - Endpoint Definitions

extension APIEndpoint {
    static func submitFeedback(body: FeedbackRequestBody) -> APIEndpoint {
        APIEndpoint(method: .post, path: "feedback", body: body)
    }

    static let myFeedback = APIEndpoint(method: .get, path: "feedback")
}
