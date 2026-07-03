import Foundation

actor APIClient {
    private let configuration: UprateConfiguration
    private let urlSession: URLSession
    private var userContext: UserContext?
    private let devicePlatform = "ios"
    private let appVersion: String

    init(configuration: UprateConfiguration, urlSession: URLSession = .shared) {
        self.configuration = configuration
        self.urlSession = urlSession
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }

    func setUserContext(_ context: UserContext) {
        self.userContext = context
    }

    func clearUserContext() {
        self.userContext = nil
    }

    func execute<T: Decodable & Sendable>(_ endpoint: APIEndpoint, as type: T.Type) async throws -> T {
        guard let userContext else {
            throw UprateError.userContextNotSet
        }

        let request = try buildRequest(for: endpoint, userContext: userContext)
        let (data, httpResponse) = try await performRequest(request)

        try mapErrorResponse(statusCode: httpResponse.statusCode, data: data, headers: httpResponse)

        do {
            return try JSONDecoder.uprate.decode(T.self, from: data)
        } catch {
            throw UprateError.unexpectedResponse(statusCode: httpResponse.statusCode)
        }
    }

    func execute(_ endpoint: APIEndpoint) async throws {
        guard let userContext else {
            throw UprateError.userContextNotSet
        }
        let request = try buildRequest(for: endpoint, userContext: userContext)
        let (data, httpResponse) = try await performRequest(request)
        try mapErrorResponse(statusCode: httpResponse.statusCode, data: data, headers: httpResponse)
    }
}

// MARK: - Private

extension APIClient {
    private func buildRequest(for endpoint: APIEndpoint, userContext: UserContext) throws -> URLRequest {
        let url = configuration.baseURL.appendingPathComponent(endpoint.path)
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        request.setValue(userContext.userId, forHTTPHeaderField: "X-SDK-User-Id")
        if let email = userContext.email {
            request.setValue(email, forHTTPHeaderField: "X-SDK-User-Email")
        }
        if let name = userContext.name {
            request.setValue(name, forHTTPHeaderField: "X-SDK-User-Name")
        }
        request.setValue(devicePlatform, forHTTPHeaderField: "X-SDK-Device-Platform")
        request.setValue(appVersion, forHTTPHeaderField: "X-SDK-App-Version")

        if let bodyData = try endpoint.bodyData {
            request.httpBody = bodyData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return request
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw UprateError.unexpectedResponse(statusCode: 0)
            }
            return (data, httpResponse)
        } catch let error as UprateError {
            throw error
        } catch {
            throw UprateError.networkError(underlying: error)
        }
    }

    private func mapErrorResponse(statusCode: Int, data: Data, headers: HTTPURLResponse) throws {
        switch statusCode {
        case 200...299:
            return
        case 401:
            // The server explains *which* wrong key type was sent (REST token,
            // secret key, ...) — surface that instead of a generic rejection.
            let errorBody = try? JSONDecoder.uprate.decode(ErrorResponse.self, from: data)
            throw UprateError.invalidApiKey(message: errorBody?.message)
        case 403:
            throw UprateError.featureNotEnabled
        case 404:
            throw UprateError.notFound
        case 422:
            let errorBody = try? JSONDecoder.uprate.decode(ValidationErrorResponse.self, from: data)
            throw UprateError.validationError(
                message: errorBody?.message ?? "Validation failed",
                errors: errorBody?.errors ?? [:]
            )
        case 429:
            let retryAfter = headers.value(forHTTPHeaderField: "Retry-After")
                .flatMap(TimeInterval.init)
            throw UprateError.rateLimited(retryAfter: retryAfter)
        default:
            let errorBody = try? JSONDecoder.uprate.decode(ErrorResponse.self, from: data)
            throw UprateError.serverError(
                statusCode: statusCode,
                message: errorBody?.message ?? "Unknown error"
            )
        }
    }
}
