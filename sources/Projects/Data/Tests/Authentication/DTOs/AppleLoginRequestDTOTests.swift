import Foundation
import Testing

@testable import DataAuthentication

@Suite("Apple 로그인 요청 DTO")
struct AppleLoginRequestDTOTests {

    @Test
    func `idToken을 인코딩하고 설명에서는 노출하지 않는다`() throws {
        let request = AppleLoginRequestDTO(idToken: "apple-id-token-secret")

        let encoded = try JSONEncoder().encode(request)
        let json = try #require(try JSONSerialization.jsonObject(with: encoded) as? [String: String])

        #expect(json["idToken"] == "apple-id-token-secret")
        #expect(!request.description.contains("apple-id-token-secret"))
        #expect(!request.debugDescription.contains("apple-id-token-secret"))
    }

}
