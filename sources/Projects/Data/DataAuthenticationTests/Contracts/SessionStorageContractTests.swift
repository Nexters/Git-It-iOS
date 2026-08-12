import Foundation
import Testing

@testable import DataAuthentication

// MARK: - SessionStorageContractTests

@Suite("SessionStorage 계약")
struct SessionStorageContractTests {
    @Test
    func `서버 세션을 원자적으로 저장하고 읽고 삭제한다`() async throws {
        let storage = SessionStorageProbe()
        let session = StoredSession(
            accessToken: "access",
            refreshToken: "refresh",
            accessExpiresAt: Date(timeIntervalSince1970: 100),
            user: .init(id: "user-1", availability: .available, displayName: nil),
        )

        try await storage.save(session)
        #expect(try await storage.load()?.user.id == "user-1")
        try await storage.delete()
        #expect(try await storage.load() == nil)
    }
}

// MARK: - SessionStorageProbe

private actor SessionStorageProbe: SessionStorage {

    // MARK: Internal

    func save(_ session: StoredSession) async throws {
        self.session = session
    }

    func load() async throws -> StoredSession? {
        session
    }

    func delete() async throws {
        session = nil
    }

    // MARK: Private

    private var session: StoredSession?

}
