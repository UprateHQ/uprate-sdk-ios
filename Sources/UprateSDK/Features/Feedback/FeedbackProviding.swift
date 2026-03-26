public protocol FeedbackProviding: Sendable {
    func submit(message: String, rating: Int?, metadata: [String: Any]?) async throws -> FeedbackResult
    func getMySubmissions() async throws -> [FeedbackSubmission]
}
