// MARK: - CurrentSessionRepository

public protocol CurrentSessionRepository: Sendable {
    func currentSession() async -> SessionRecord?
}
