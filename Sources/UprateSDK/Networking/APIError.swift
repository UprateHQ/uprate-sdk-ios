import Foundation

public enum UprateError: Error, Sendable {
    /// UprateSDK.configure() or init() has not been called
    case notInitialized

    /// setUserContext() has not been called
    case userContextNotSet

    /// 401 — API key is invalid, revoked, or missing
    case invalidApiKey

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
        case .invalidApiKey:
            "Invalid or revoked API key."
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
}

struct ValidationErrorResponse: Decodable, Sendable {
    let message: String
    let errors: [String: [String]]
}
