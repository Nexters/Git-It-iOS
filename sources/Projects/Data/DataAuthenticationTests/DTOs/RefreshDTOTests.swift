import Foundation
import Testing

@testable import DataAuthentication

@Suite("세션 갱신 DTO")
struct RefreshDTOTests {
    @Test
    func `공급자와 무관한 갱신 입력과 결과를 표현한다`() {
        let request = RefreshRequestDTO(refreshToken: "refresh-secret")
        let response = RefreshResponseDTO(
            accessToken: "new-access-secret",
            accessExpiresAt: Date(timeIntervalSince1970: 200),
            replacementRefreshToken: nil,
        )

        #expect(request.refreshToken == "refresh-secret")
        #expect(response.accessToken == "new-access-secret")
        #expect(response.replacementRefreshToken == nil)
        #expect(Set(Mirror(reflecting: request).children.compactMap(\.label)) == ["refreshToken"])
        #expect(Set(Mirror(reflecting: response).children.compactMap(\.label)) == [
            "accessToken",
            "accessExpiresAt",
            "replacementRefreshToken",
        ])
        #expect(DataAuthenticationError.refreshRejectedOrExpired != .temporarilyUnavailable)
    }
}
