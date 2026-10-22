public struct UserContext: Equatable, Sendable {
    public let userId: String
    public let email: String?
    public let name: String?
    public let userToken: String?

    public init(userId: String, email: String? = nil, name: String? = nil, userToken: String? = nil) {
        self.userId = userId
        self.email = email
        self.name = name
        self.userToken = userToken
    }
}
