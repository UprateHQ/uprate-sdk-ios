import Testing
import Foundation
@testable import UprateSDK

extension SerializedTests {
@Suite("APIClient")
struct APIClientTests {

    @Test("throws userContextNotSet when no user context is set")
    func throwsWithoutUserContext() async {
        MockURLProtocol.reset()
        let client = APIClient(configuration: TestFixtures.testConfiguration, urlSession: .mocked)

        await #expect(throws: UprateError.self) {
            try await client.execute(
                APIEndpoint(method: .get, path: "roadmap"),
                as: EmptyResponse.self
            )
        }
    }

    @Test("sends correct authorization header")
    func sendsAuthHeader() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.register(path: "roadmap", statusCode: 200, json: "{}")

        let client = APIClient(configuration: TestFixtures.testConfiguration, urlSession: .mocked)
        await client.setUserContext(UserContext(userId: "user_1"))

        _ = try? await client.execute(
            APIEndpoint(method: .get, path: "roadmap"),
            as: EmptyResponse.self
        )

        let authHeader = MockURLProtocol.lastRequest?.value(forHTTPHeaderField: "Authorization")
        #expect(authHeader == "Bearer \(TestFixtures.validAPIKey)")
    }

    @Test("sends user context headers")
    func sendsUserContextHeaders() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.register(path: "roadmap", statusCode: 200, json: "{}")

        let client = APIClient(configuration: TestFixtures.testConfiguration, urlSession: .mocked)
        await client.setUserContext(UserContext(userId: "user_42", email: "test@example.com", name: "Test User"))

        _ = try? await client.execute(
            APIEndpoint(method: .get, path: "roadmap"),
            as: EmptyResponse.self
        )

        let request = MockURLProtocol.lastRequest
        #expect(request?.value(forHTTPHeaderField: "X-SDK-User-Id") == "user_42")
        #expect(request?.value(forHTTPHeaderField: "X-SDK-User-Email") == "test@example.com")
        #expect(request?.value(forHTTPHeaderField: "X-SDK-User-Name") == "Test User")
        #expect(request?.value(forHTTPHeaderField: "X-SDK-Device-Platform") == "ios")
        #expect(request?.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test("omits optional headers when not set")
    func omitsOptionalHeaders() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.register(path: "roadmap", statusCode: 200, json: "{}")

        let client = APIClient(configuration: TestFixtures.testConfiguration, urlSession: .mocked)
        await client.setUserContext(UserContext(userId: "user_1"))

        _ = try? await client.execute(
            APIEndpoint(method: .get, path: "roadmap"),
            as: EmptyResponse.self
        )

        let request = MockURLProtocol.lastRequest
        #expect(request?.value(forHTTPHeaderField: "X-SDK-User-Email") == nil)
        #expect(request?.value(forHTTPHeaderField: "X-SDK-User-Name") == nil)
    }

    @Test("maps 401 to invalidApiKey")
    func maps401() async {
        MockURLProtocol.reset()
        MockURLProtocol.register(
            path: "roadmap",
            statusCode: 401,
            json: #"{"message": "Invalid or missing SDK API key."}"#
        )

        let client = APIClient(configuration: TestFixtures.testConfiguration, urlSession: .mocked)
        await client.setUserContext(UserContext(userId: "user_1"))

        await #expect(throws: UprateError.self) {
            try await client.execute(
                APIEndpoint(method: .get, path: "roadmap"),
                as: EmptyResponse.self
            )
        }
    }

    @Test("surfaces server message on 401")
    func surfacesServerMessageOn401() async {
        MockURLProtocol.reset()
        let serverMessage = "This does not look like an SDK key. Keys from Settings -> API keys "
            + "only work with the REST API; the mobile SDK needs a publishable key (uprt_pub_...)."
        MockURLProtocol.register(
            path: "roadmap",
            statusCode: 401,
            json: #"{"message": "\#(serverMessage)"}"#
        )

        let client = APIClient(configuration: TestFixtures.testConfiguration, urlSession: .mocked)
        await client.setUserContext(UserContext(userId: "user_1"))

        do {
            _ = try await client.execute(
                APIEndpoint(method: .get, path: "roadmap"),
                as: EmptyResponse.self
            )
            Issue.record("Expected invalidApiKey error")
        } catch let UprateError.invalidApiKey(message) {
            #expect(message == serverMessage)
            #expect(UprateError.invalidApiKey(message: message).localizedDescription == serverMessage)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("maps 403 to featureNotEnabled")
    func maps403() async {
        MockURLProtocol.reset()
        MockURLProtocol.register(
            path: "roadmap",
            statusCode: 403,
            json: #"{"message": "SDK access not enabled."}"#
        )

        let client = APIClient(configuration: TestFixtures.testConfiguration, urlSession: .mocked)
        await client.setUserContext(UserContext(userId: "user_1"))

        await #expect(throws: UprateError.self) {
            try await client.execute(
                APIEndpoint(method: .get, path: "roadmap"),
                as: EmptyResponse.self
            )
        }
    }

    @Test("maps 404 to notFound")
    func maps404() async {
        MockURLProtocol.reset()
        MockURLProtocol.register(
            path: "roadmap",
            statusCode: 404,
            json: #"{"message": "Not found."}"#
        )

        let client = APIClient(configuration: TestFixtures.testConfiguration, urlSession: .mocked)
        await client.setUserContext(UserContext(userId: "user_1"))

        await #expect(throws: UprateError.self) {
            try await client.execute(
                APIEndpoint(method: .get, path: "roadmap"),
                as: EmptyResponse.self
            )
        }
    }

    @Test("maps 422 to validationError with field details")
    func maps422() async {
        MockURLProtocol.reset()
        MockURLProtocol.register(
            path: "roadmap",
            statusCode: 422,
            json: #"{"message": "The title field is required.", "errors": {"title": ["The title field is required."]}}"#
        )

        let client = APIClient(configuration: TestFixtures.testConfiguration, urlSession: .mocked)
        await client.setUserContext(UserContext(userId: "user_1"))

        do {
            _ = try await client.execute(
                APIEndpoint(method: .get, path: "roadmap"),
                as: EmptyResponse.self
            )
            Issue.record("Expected validationError")
        } catch let error as UprateError {
            guard case .validationError(let message, let errors) = error else {
                Issue.record("Expected validationError, got \(error)")
                return
            }
            #expect(message == "The title field is required.")
            #expect(errors["title"] == ["The title field is required."])
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("maps 429 to rateLimited with Retry-After header")
    func maps429WithRetryAfter() async {
        MockURLProtocol.reset()
        MockURLProtocol.register(
            path: "roadmap",
            statusCode: 429,
            json: #"{"message": "Too many requests."}"#,
            headers: ["Retry-After": "30"]
        )

        let client = APIClient(configuration: TestFixtures.testConfiguration, urlSession: .mocked)
        await client.setUserContext(UserContext(userId: "user_1"))

        do {
            _ = try await client.execute(
                APIEndpoint(method: .get, path: "roadmap"),
                as: EmptyResponse.self
            )
            Issue.record("Expected rateLimited")
        } catch let error as UprateError {
            guard case .rateLimited(let retryAfter) = error else {
                Issue.record("Expected rateLimited, got \(error)")
                return
            }
            #expect(retryAfter == 30.0)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("maps 500 to serverError")
    func maps500() async {
        MockURLProtocol.reset()
        MockURLProtocol.register(
            path: "roadmap",
            statusCode: 500,
            json: #"{"message": "Internal server error."}"#
        )

        let client = APIClient(configuration: TestFixtures.testConfiguration, urlSession: .mocked)
        await client.setUserContext(UserContext(userId: "user_1"))

        do {
            _ = try await client.execute(
                APIEndpoint(method: .get, path: "roadmap"),
                as: EmptyResponse.self
            )
            Issue.record("Expected serverError")
        } catch let error as UprateError {
            guard case .serverError(let statusCode, let message) = error else {
                Issue.record("Expected serverError, got \(error)")
                return
            }
            #expect(statusCode == 500)
            #expect(message == "Internal server error.")
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("clears user context and subsequent requests fail")
    func clearUserContext() async {
        MockURLProtocol.reset()
        let client = APIClient(configuration: TestFixtures.testConfiguration, urlSession: .mocked)
        await client.setUserContext(UserContext(userId: "user_1"))
        await client.clearUserContext()

        await #expect(throws: UprateError.self) {
            try await client.execute(
                APIEndpoint(method: .get, path: "roadmap"),
                as: EmptyResponse.self
            )
        }
    }
}
} // extension SerializedTests

// Minimal decodable type for tests that don't care about the response body
private struct EmptyResponse: Decodable, Sendable {}
