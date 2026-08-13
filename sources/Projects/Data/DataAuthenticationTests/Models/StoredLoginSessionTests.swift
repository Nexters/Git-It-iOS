import Foundation
import Testing

@testable import DataAuthentication

@Suite("StoredLoginSession")
struct StoredLoginSessionTests {
    @Test
    func `서버 세션 값과 사용자만 보유한다`() {
        let user = LoginSessionResponseDTO.User(
            id: "user-1",
            availability: .available,
            displayName: nil,
        )
        let session = StoredLoginSession(
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
