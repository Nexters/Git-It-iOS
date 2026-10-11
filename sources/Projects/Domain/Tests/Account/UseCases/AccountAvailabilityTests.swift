import Foundation
import Testing

@testable import DomainUseCaseImplementation

@Suite("Account 로그인 가용성")
struct AccountAvailabilityTests {

    // MARK: Internal

    @Test
    func `공유 로그인 표시가 없으면 앱 실행이 필요하다`() async {
        let account = Self.makeAccount(
            sharedSignInState: nil,
            hasUsableCredential: true,
        )

        #expect(await account.signInAvailability() == .appLaunchRequired)
    }

    @Test
    func `공유 로그인 표시가 로그아웃이면 로그인이 필요하다`() async {
        let account = Self.makeAccount(
            sharedSignInState: false,
            hasUsableCredential: true,
        )

        #expect(await account.signInAvailability() == .signInRequired)
    }

    @Test
    func `사용 가능한 인증 정보가 없으면 로그인이 필요하다`() async {
        let account = Self.makeAccount(
            sharedSignInState: true,
            hasUsableCredential: false,
        )

        #expect(await account.signInAvailability() == .signInRequired)
    }

    @Test
    func `로그인 표시와 인증 정보가 모두 있으면 로그인 상태다`() async {
        let account = Self.makeAccount(
            sharedSignInState: true,
            hasUsableCredential: true,
        )

        #expect(await account.signInAvailability() == .signedIn)
    }

    // MARK: Private

    private static func makeAccount(
        sharedSignInState: Bool?,
        hasUsableCredential: Bool,
    ) -> Account {
        Account(
            authenticationRepository: StubAuthenticationRepository(),
            signInRepository: StubSignInRepository(
                sharedSignInState: sharedSignInState,
                hasUsableCredential: hasUsableCredential,
            ),
            withdrawalRepository: StubWithdrawalRepository(),
            policyConsentRepository: InMemoryPolicyConsentRepository(),
            policyDocuments: [],
            signInInvalidations: { AsyncStream { _ in } },
        )
    }

}
