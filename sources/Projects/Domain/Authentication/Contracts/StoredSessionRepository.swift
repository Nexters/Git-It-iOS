// MARK: - StoredSessionRepository

public protocol StoredSessionRepository: Sendable {
    func currentSession() async -> SessionRecord?
}
