import Testing

@testable import InfrastructureAuthentication

@Suite("AppleCredentialStateProvider")
struct AppleCredentialStateProviderTests {
    @Test
    func `Apple 자격 증명 상태와 조회 오류를 Infrastructure 상태로 격리한다`() async {
        let provider = AppleCredentialStateProvider(stateLookup: { _ in .authorized })
        #expect(await provider.state(for: "user") == .authorized)
        #expect(AppleCredentialStateProvider.map(.revoked) == .revoked)
        #expect(AppleCredentialStateProvider.map(.notFound) == .notFound)
        #expect(AppleCredentialStateProvider.map(.transferred) == .transferred)
    }

    @Test
    func `조회가 실패하면 일시적으로 확인할 수 없는 상태로 바꾼다`() async {
        struct LookupFailure: Error { }
        let provider = AppleCredentialStateProvider(stateLookup: { _ in throw LookupFailure() })
        #expect(await provider.state(for: "user") == .temporarilyUnavailable)
    }
}
