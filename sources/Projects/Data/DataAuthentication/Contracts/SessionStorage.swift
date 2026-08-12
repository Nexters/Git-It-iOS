public protocol SessionStorage: Sendable {
    func save(_ session: StoredSession) async throws
    func load() async throws -> StoredSession?
    func delete() async throws
}
