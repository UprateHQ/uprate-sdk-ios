public struct UserContext: Sendable {
    public let userId: String
    public let email: String?
    public let name: String?

    public init(userId: String, email: String? = nil, name: String? = nil) {
        self.userId = userId
        self.email = email
        self.name = name
    }
}
