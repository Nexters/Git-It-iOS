import Testing

@testable import DataAuthentication

@Suite("세션 시작 요청 DTO")
struct SessionStartRequestDTOTests {
    @Test
    func `공급자 중립 방식과 단발성 payload만 보유한다`() {
        let request = SessionStartRequestDTO(
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
