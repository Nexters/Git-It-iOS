public protocol LoginSessionStorage: Sendable {
    func save(_ session: StoredLoginSession) async throws
    func load() async throws -> StoredLoginSession?
    func delete() async throws
}
