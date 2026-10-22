import Foundation

public enum UprateError: Error, Sendable {
    /// UprateSDK.configure() or init() has not been called
    case notInitialized

    /// setUserContext() has not been called
    case userContextNotSet

    /// The user context changed while the request was in flight, so its result was dropped
    case userContextChanged

    /// 401 — API key is invalid, revoked, or missing. Carries the server's
    /// explanation when available (e.g. a REST API token was used instead of
    /// an SDK publishable key).
    case invalidApiKey(message: String? = nil)

    /// 401 — the signed user token is required or invalid.
    case userTokenRejected(message: String)

    /// 403 — SDK feature access not enabled in the dashboard
    case featureNotEnabled

    /// 404 — resource not found or unpublished
    case notFound

    /// 422 — validation or business rule violation
    case validationError(message: String, errors: [String: [String]])

    /// 429 — rate limited
    case rateLimited(retryAfter: TimeInterval?)

    /// Network connectivity failure
    case networkError(underlying: any Error)

    /// 5xx — server error
    case serverError(statusCode: Int, message: String)

    /// Server returned a response that could not be parsed
    case unexpectedResponse(statusCode: Int)
}

extension UprateError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            "UprateSDK has not been configured. Call UprateSDK.configure(apiKey:) first."
        case .userContextNotSet:
            "User context is not set. Call setUserContext(userId:) before using SDK features."
        case .userContextChanged:
            "The user changed while the request was in progress, so its result was dropped."
        case .invalidApiKey(let message):
            message ?? "Invalid or revoked API key."
        case .userTokenRejected(let message):
            message
        case .featureNotEnabled:
            "This feature is not enabled for your app. Check your UprateHQ dashboard settings."
        case .notFound:
            "The requested resource was not found."
        case .validationError(let message, _):
            message
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                "Rate limited. Retry after \(Int(seconds)) seconds."
            } else {
                "Rate limited. Please try again later."
            }
        case .networkError(let underlying):
            "Network error: \(underlying.localizedDescription)"
        case .serverError(_, let message):
            message
        case .unexpectedResponse(let statusCode):
            "Unexpected response from server (HTTP \(statusCode))."
        }
    }
}

// MARK: - Internal Error Response Bodies

struct ErrorResponse: Decodable, Sendable {
    let message: String
    let code: String?
}

struct ValidationErrorResponse: Decodable, Sendable {
    let message: String
    let errors: [String: [String]]
}
