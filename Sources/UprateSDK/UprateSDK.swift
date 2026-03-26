import Foundation

public final class UprateSDK: Sendable {

    // MARK: - Static Convenience

    private static let _lock = NSLock()
    nonisolated(unsafe) private static var _sharedInstance: UprateSDK?

    /// Access the configured SDK instance. Throws `UprateError.notInitialized` if `configure()` has not been called.
    public static var shared: UprateSDK {
        get throws {
            _lock.lock()
            defer { _lock.unlock() }
            guard let instance = _sharedInstance else {
                throw UprateError.notInitialized
            }
            return instance
        }
    }

    /// Configure the SDK with your publishable API key. Call this once at app launch.
    /// This does not make any network requests.
    public static func configure(apiKey: String, baseURL: URL? = nil) {
        let config: UprateConfiguration
        if let baseURL {
            config = UprateConfiguration(apiKey: apiKey, baseURL: baseURL)
        } else {
            config = UprateConfiguration(apiKey: apiKey)
        }
        _lock.lock()
        defer { _lock.unlock() }
        _sharedInstance = UprateSDK(configuration: config)
    }

    /// Reset the SDK (useful in tests). Removes the shared instance.
    public static func reset() {
        _lock.lock()
        defer { _lock.unlock() }
        _sharedInstance = nil
    }

    // MARK: - Instance

    /// Roadmap feature module — fetch items, vote, submit requests.
    public let roadmap: UprateRoadmap

    /// Feedback feature module — submit feedback, list submissions.
    public let feedback: UprateFeedback

    /// Reviews feature module — record review prompt signals for matching.
    public let reviews: UprateReviews

    private let apiClient: APIClient

    /// Create an SDK instance directly (for dependency injection and testing).
    /// For most apps, use `UprateSDK.configure()` and `UprateSDK.shared` instead.
    public init(configuration: UprateConfiguration, urlSession: URLSession = .shared) {
        self.apiClient = APIClient(configuration: configuration, urlSession: urlSession)
        self.roadmap = UprateRoadmap(apiClient: apiClient)
        self.feedback = UprateFeedback(apiClient: apiClient)
        self.reviews = UprateReviews(apiClient: apiClient)
    }

    /// Set the current user's identity. Must be called before using any feature.
    public func setUserContext(userId: String, email: String? = nil, name: String? = nil) async {
        await apiClient.setUserContext(UserContext(userId: userId, email: email, name: name))
    }

    /// Clear the current user's identity (e.g., on logout).
    public func clearUserContext() async {
        await apiClient.clearUserContext()
    }
}
