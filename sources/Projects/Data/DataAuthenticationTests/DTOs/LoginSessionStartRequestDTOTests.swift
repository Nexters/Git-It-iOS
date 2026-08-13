import Testing

@testable import DataAuthentication

@Suite("LoginSessionStartRequestDTO")
struct LoginSessionStartRequestDTOTests {
    @Test
    func `공급자 중립 방식과 단발성 payload만 보유한다`() {
        let request = LoginSessionStartRequestDTO(
            methodIdentifier: "social-provider",
            opaquePayload: .init(bytes: [7, 8, 9]),
        )

        #expect(request.methodIdentifier == "social-provider")
        #expect(request.opaquePayload.bytes == [7, 8, 9])
        #expect(Set(Mirror(reflecting: request).children.compactMap(\.label)) == [
            "methodIdentifier",
            "opaquePayload",
        ])
    }
}
