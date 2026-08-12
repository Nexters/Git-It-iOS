import Testing

@testable import DataAuthentication

@Suite("외부 인증 evidence")
struct ExternalAuthenticationEvidenceTests {
    @Test
    func `공급자 중립 참조와 불투명 payload만 보유한다`() {
        let evidence = ExternalAuthenticationEvidence(
            methodIdentifier: "social-provider",
            providerSubjectReference: "subject-reference",
            opaquePayload: .init(bytes: [1, 2, 3]),
        )

        #expect(evidence.methodIdentifier == "social-provider")
        #expect(evidence.providerSubjectReference == "subject-reference")
        #expect(evidence.opaquePayload.bytes == [1, 2, 3])
        #expect(Set(Mirror(reflecting: evidence).children.compactMap(\.label)) == [
            "methodIdentifier",
            "providerSubjectReference",
            "opaquePayload",
        ])
        #expect(!(evidence.opaquePayload is any Equatable))
        #expect(!String(reflecting: evidence.opaquePayload).contains("1, 2, 3"))
    }
}
