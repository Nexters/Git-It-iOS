import Testing

@testable import GitIt

@Suite("PolicyManifestLoader")
struct PolicyManifestTests {

    @Test
    func `번들 manifest는 개인정보 처리방침과 서비스 이용 약관을 승인 계약대로 제공한다`() throws {
        let documents = try PolicyManifestLoader.loadPolicyDocuments()

        #expect(documents.count == 2)

        let privacyPolicy = try #require(documents.first { $0.identifier == "privacy-policy" })
        #expect(privacyPolicy.version == "1")
        #expect(privacyPolicy.isRequired)
        #expect(privacyPolicy.approvedURL.scheme == "https")
        #expect(!privacyPolicy.displayName.isEmpty)

        let termsOfService = try #require(documents.first { $0.identifier == "terms-of-service" })
        #expect(termsOfService.version == "1")
        #expect(termsOfService.isRequired)
        #expect(termsOfService.approvedURL.scheme == "https")
        #expect(!termsOfService.displayName.isEmpty)
    }

    @Test
    func `manifest 리소스가 없으면 resourceMissing 오류를 던진다`() {
        #expect(throws: PolicyManifestLoader.LoadError.resourceMissing) {
            try PolicyManifestLoader.loadPolicyDocuments(resourceName: "does-not-exist")
        }
    }

}
