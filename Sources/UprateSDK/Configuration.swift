import Foundation

public struct UprateConfiguration: Sendable {
    public let apiKey: String
    public let baseURL: URL

    public init(
        apiKey: String,
        baseURL: URL = URL(string: "https://app.upratehq.com/api/sdk/v1")!  // swiftlint:disable:this force_unwrapping
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
    }
}
