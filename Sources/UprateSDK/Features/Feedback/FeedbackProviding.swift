public protocol FeedbackProviding: Sendable {
    func submit(message: String, rating: Int?, metadata: [String: Any]?) async throws -> FeedbackResult
    func getMySubmissions() async throws -> [FeedbackSubmission]
    func getUnreadReplies() async throws -> [FeedbackReply]
    func markRead(_ replies: [FeedbackReply]) async throws
}
