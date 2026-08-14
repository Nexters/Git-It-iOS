import Testing

@testable import InfrastructureAuthentication

@Suite("AppleCredentialStateProvider")
struct AppleCredentialStateProviderTests {
    @Test
    func `Apple 상태와 revoked 알림 및 조회 오류를 Infrastructure 상태로 격리한다`() async {
        let provider = AppleCredentialStateProvider(stateLookup: { _ in .authorized })
        #expect(await provider.state(for: "user") == .authorized)
        #expect(AppleCredentialStateProvider.map(.revoked) == .revoked)
        #expect(AppleCredentialStateProvider.map(.notFound) == .notFound)
        #expect(AppleCredentialStateProvider.map(.transferred) == .transferred)

        let changes = await provider.changes()
        var iterator = changes.makeAsyncIterator()
        await provider.receiveRevocation(for: "user")
        #expect(await iterator.next() == .revoked)
    }
}
