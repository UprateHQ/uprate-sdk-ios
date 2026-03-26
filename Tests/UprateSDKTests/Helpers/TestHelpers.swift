import Foundation
@testable import UprateSDK

enum TestFixtures {
    static let validAPIKey = "uprt_pub_" + String(repeating: "a", count: 64)

    static let testBaseURL = URL(string: "https://test.upratehq.com/api/sdk/v1")!  // swiftlint:disable:this force_unwrapping

    static var testConfiguration: UprateConfiguration {
        UprateConfiguration(apiKey: validAPIKey, baseURL: testBaseURL)
    }
}
