import Testing
import Foundation
@testable import UprateSDK

extension SerializedTests {
@Suite("UprateSDK Configuration")
struct ConfigurationTests {

    // MARK: - Instance-based

    @Test("instance-based SDK exposes roadmap module")
    func instanceBasedSDK() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.register(path: "roadmap", statusCode: 200, json: """
        {"settings": {"voting_enabled": true, "show_vote_count": true, "voting_excluded_statuses": []}, "items": []}
        """)

        let config = UprateConfiguration(
            apiKey: TestFixtures.validAPIKey,
            baseURL: TestFixtures.testBaseURL
        )
        let sdk = UprateSDK(configuration: config, urlSession: .mocked)
        await sdk.setUserContext(userId: "user_1")

        let result = try await sdk.roadmap.getItems()
        #expect(result.items.isEmpty)
    }

    @Test("setUserContext and clearUserContext work correctly")
    func userContextLifecycle() async {
        MockURLProtocol.reset()
        MockURLProtocol.register(path: "roadmap", statusCode: 200, json: """
        {"settings": {"voting_enabled": true, "show_vote_count": true, "voting_excluded_statuses": []}, "items": []}
        """)

        let sdk = UprateSDK(
            configuration: TestFixtures.testConfiguration,
            urlSession: .mocked
        )

        // Before setting context — should throw
        await #expect(throws: UprateError.self) {
            try await sdk.roadmap.getItems()
        }

        // After setting context — should work
        await sdk.setUserContext(userId: "user_1")
        let result = try? await sdk.roadmap.getItems()
        #expect(result != nil)

        // After clearing context — should throw again
        await sdk.clearUserContext()
        await #expect(throws: UprateError.self) {
            try await sdk.roadmap.getItems()
        }
    }

    @Test("custom baseURL is used in requests")
    func customBaseURL() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.register(path: "roadmap", statusCode: 200, json: """
        {"settings": {"voting_enabled": true, "show_vote_count": true, "voting_excluded_statuses": []}, "items": []}
        """)

        let customURL = URL(string: "https://staging.upratehq.com/api/sdk/v1")!  // swiftlint:disable:this force_unwrapping
        let config = UprateConfiguration(apiKey: TestFixtures.validAPIKey, baseURL: customURL)
        let sdk = UprateSDK(configuration: config, urlSession: .mocked)
        await sdk.setUserContext(userId: "user_1")

        _ = try await sdk.roadmap.getItems()

        let requestURL = MockURLProtocol.lastRequest?.url?.absoluteString ?? ""
        #expect(requestURL.hasPrefix("https://staging.upratehq.com"))
    }
}
} // extension SerializedTests
