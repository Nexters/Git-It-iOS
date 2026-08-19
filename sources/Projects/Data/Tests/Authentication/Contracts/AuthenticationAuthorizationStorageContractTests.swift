import Testing

@testable import DataAuthentication

// MARK: - AuthenticationAuthorizationStorageContractTests

@Suite("AuthenticationAuthorizationStorage 계약")
struct AuthenticationAuthorizationStorageContractTests {
    @Test
    func `인증 참조를 서버 세션과 분리해 저장하고 읽고 삭제한다`() async throws {
        let storage = AuthenticationAuthorizationStorageProbe()
        let reference = StoredAuthorizationReference(
            methodIdentifier: "social-provider",
            providerSubjectReference: "subject-reference",
        )

        try await storage.save(reference)
        #expect(try await storage.load() == reference)
        try await storage.delete()
        #expect(try await storage.load() == nil)
    }
}

// MARK: - AuthenticationAuthorizationStorageProbe

private actor AuthenticationAuthorizationStorageProbe: AuthenticationAuthorizationStorage {

    // MARK: Internal

    func save(_ reference: StoredAuthorizationReference) async throws {
        self.reference = reference
    }

    func load() async throws -> StoredAuthorizationReference? {
        reference
    }

    func delete() async throws {
        reference = nil
    }

    // MARK: Private

    private var reference: StoredAuthorizationReference?

}
