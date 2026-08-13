import Foundation
import Testing

@testable import DataAuthentication

@Suite("LoginSessionResponseDTO")
struct LoginSessionResponseDTOTests {
    @Test
    func `사용자와 Git It 세션 값만 보유한다`() {
        let user = LoginSessionResponseDTO.User(
            id: "user-1",
            availability: .available,
            displayName: nil,
        )
        let response = LoginSessionResponseDTO(
            user: user,
            accessToken: "access-secret",
            refreshToken: "refresh-secret",
            accessExpiresAt: Date(timeIntervalSince1970: 100),
        )

        #expect(response.user == user)
        #expect(response.accessToken == "access-secret")
        #expect(response.refreshToken == "refresh-secret")
        #expect(Set(Mirror(reflecting: response).children.compactMap(\.label)) == [
            "user",
            "accessToken",
            "refreshToken",
            "accessExpiresAt",
        ])
    }
}
