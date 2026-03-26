public protocol ReviewSignalProviding: Sendable {
    func recordPrompt() async throws -> ReviewSignalResult
}
