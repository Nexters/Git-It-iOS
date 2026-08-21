import Foundation
import Testing

@testable import DataAuthentication

@Suite("로그인 응답 DTO")
struct LoginResponseDTOTests {

    @Test
    func `필드를 디코딩하고 토큰을 설명에 노출하지 않는다`() throws {
        let json = Data(#"""
            {"accessToken":"access-secret","refreshToken":"refresh-secret","needsCuration":true}
            """#.utf8)

        let response = try JSONDecoder().decode(LoginResponseDTO.self, from: json)

        #expect(response.accessToken == "access-secret")
        #expect(response.refreshToken == "refresh-secret")
        #expect(response.needsCuration)
        #expect(!response.description.contains("access-secret"))
        #expect(!response.description.contains("refresh-secret"))
        #expect(!response.debugDescription.contains("access-secret"))
        #expect(!response.debugDescription.contains("refresh-secret"))
    }

}
