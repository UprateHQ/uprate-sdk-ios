import Testing
import Foundation
@testable import UprateSDK

extension SerializedTests {
    @Suite("UprateReviews")
    struct UprateReviewsTests {

        private func makeReviews() async -> UprateReviews {
            MockURLProtocol.reset()
            let client = APIClient(configuration: TestFixtures.testConfiguration, urlSession: .mocked)
            await client.setUserContext(UserContext(userId: "test_user"))
            return UprateReviews(apiClient: client)
        }

        @Test("recordPrompt returns ReviewSignalResult")
        func recordPromptSuccess() async throws {
            let reviews = await makeReviews()
            MockURLProtocol.register(path: "review-signals", statusCode: 201, json: """
            {
                "uuid": "sig-1",
                "status": "recorded",
                "expires_at": "2026-04-10T14:23:05+00:00"
            }
            """)

            let result = try await reviews.recordPrompt()

            #expect(result.id == "sig-1")
            #expect(result.status == "recorded")
        }

        @Test("recordPrompt uses POST method to /review-signals")
        func recordPromptMethod() async throws {
            let reviews = await makeReviews()
            MockURLProtocol.register(path: "review-signals", statusCode: 201, json: """
            {"uuid": "sig-1", "status": "recorded", "expires_at": "2026-04-10T14:23:05+00:00"}
            """)

            _ = try await reviews.recordPrompt()

            #expect(MockURLProtocol.lastRequest?.httpMethod == "POST")
            #expect(MockURLProtocol.lastRequest?.value(forHTTPHeaderField: "Content-Type") == "application/json")
        }

        @Test("recordPrompt sends triggered_at and device metadata in body")
        func recordPromptBody() async throws {
            let reviews = await makeReviews()
            MockURLProtocol.register(path: "review-signals", statusCode: 201, json: """
            {"uuid": "sig-1", "status": "recorded", "expires_at": "2026-04-10T14:23:05+00:00"}
            """)

            _ = try await reviews.recordPrompt()

            let body = MockURLProtocol.lastRequest?.httpBody
            #expect(body != nil)
            if let body {
                let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
                #expect(json?["triggered_at"] != nil)
                let metadata = json?["metadata"] as? [String: Any]
                #expect(metadata?["device"] != nil)
            }
        }

        @Test("recordPrompt with 429 throws rateLimited")
        func recordPromptRateLimited() async {
            let reviews = await makeReviews()
            MockURLProtocol.register(
                path: "review-signals",
                statusCode: 429,
                json: #"{"message": "Too Many Attempts."}"#,
                headers: ["Retry-After": "86400"]
            )

            do {
                _ = try await reviews.recordPrompt()
                Issue.record("Expected rateLimited")
            } catch let error as UprateError {
                guard case .rateLimited = error else {
                    Issue.record("Expected rateLimited, got \(error)")
                    return
                }
            } catch {
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test("recordPrompt without user context throws")
        func recordPromptNoUserContext() async {
            MockURLProtocol.reset()
            let client = APIClient(configuration: TestFixtures.testConfiguration, urlSession: .mocked)
            let reviews = UprateReviews(apiClient: client)

            await #expect(throws: UprateError.self) {
                try await reviews.recordPrompt()
            }
        }
    }
}
