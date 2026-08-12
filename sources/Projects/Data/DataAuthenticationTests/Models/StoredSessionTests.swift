import Foundation
import Testing

@testable import DataAuthentication

@Suite("저장 세션")
struct StoredSessionTests {
    @Test
    func `서버 세션 값과 사용자만 보유한다`() {
        let user = SessionResponseDTO.User(id: "user-1", availability: .available, displayName: nil)
        let session = StoredSession(
            accessToken: "access-secret",
            refreshToken: "refresh-secret",
            accessExpiresAt: Date(timeIntervalSince1970: 100),
            user: user,
        )

        #expect(session.user == user)
        #expect(Set(Mirror(reflecting: session).children.compactMap(\.label)) == [
            "accessToken",
            "refreshToken",
            "accessExpiresAt",
            "user",
        ])
        #expect(!Mirror(reflecting: session).children.compactMap(\.label).contains("appleUserID"))
        #expect(!Mirror(reflecting: session).children.compactMap(\.label).contains("providerSubjectReference"))
    }
}
