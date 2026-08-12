import Testing

@testable import DataAuthentication

@Suite("저장 인증 참조")
struct StoredAuthorizationReferenceTests {
    @Test
    func `서버 세션과 분리된 공급자 중립 참조만 보유한다`() {
        let reference = StoredAuthorizationReference(
            methodIdentifier: "social-provider",
            providerSubjectReference: "subject-reference",
        )

        #expect(reference.methodIdentifier == "social-provider")
        #expect(reference.providerSubjectReference == "subject-reference")
        #expect(Set(Mirror(reflecting: reference).children.compactMap(\.label)) == [
            "methodIdentifier",
            "providerSubjectReference",
        ])
    }
}
