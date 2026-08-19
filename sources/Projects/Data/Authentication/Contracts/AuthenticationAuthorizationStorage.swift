public protocol AuthenticationAuthorizationStorage: Sendable {
    func save(_ reference: StoredAuthorizationReference) async throws
    func load() async throws -> StoredAuthorizationReference?
    func delete() async throws
}
