import Foundation

actor APIClient {
    private let configuration: UprateConfiguration
    private let urlSession: URLSession
    private var userContext: UserContext?
    private var userContextVersion = 0
    private let devicePlatform = "ios"
    private let appVersion: String

    init(configuration: UprateConfiguration, urlSession: URLSession = .shared) {
        self.configuration = configuration
        self.urlSession = urlSession
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }

    func setUserContext(_ context: UserContext) {
        // Apps set the same identity again on every session refresh; that must not drop replies in flight.
        guard context != userContext else { return }
        self.userContext = context
        userContextVersion += 1
    }

    func clearUserContext() {
        self.userContext = nil
        userContextVersion += 1
    }

    /// With `sameUser`, a response that arrives after the user context changed is dropped,
    /// so one person's private data never reaches the next one on the device.
    func execute<T: Decodable & Sendable>(_ endpoint: APIEndpoint, as type: T.Type, sameUser: Bool = false) async throws -> T {
        let data = try await send(endpoint, sameUser: sameUser)

        do {
            return try JSONDecoder.uprate.decode(T.self, from: data.body)
        } catch {
            throw UprateError.unexpectedResponse(statusCode: data.statusCode)
        }
    }

    func execute(_ endpoint: APIEndpoint, sameUser: Bool = false) async throws {
        _ = try await send(endpoint, sameUser: sameUser)
    }

    private func send(_ endpoint: APIEndpoint, sameUser: Bool) async throws -> (body: Data, statusCode: Int) {
        guard let userContext else {
            throw UprateError.userContextNotSet
        }
        let contextVersion = userContextVersion
        let request = try buildRequest(for: endpoint, userContext: userContext)
        let (data, httpResponse) = try await performRequest(request)
        if sameUser && contextVersion != userContextVersion {
            throw UprateError.userContextChanged
        }
        try mapErrorResponse(statusCode: httpResponse.statusCode, data: data, headers: httpResponse)
        return (data, httpResponse.statusCode)
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
        if let userToken = userContext.userToken {
            request.setValue(userToken, forHTTPHeaderField: "X-SDK-User-Token")
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
            let errorBody = try? JSONDecoder.uprate.decode(ErrorResponse.self, from: data)
            if let errorBody, errorBody.code == "user_token_required" || errorBody.code == "user_token_invalid" {
                throw UprateError.userTokenRejected(message: errorBody.message)
            }
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
