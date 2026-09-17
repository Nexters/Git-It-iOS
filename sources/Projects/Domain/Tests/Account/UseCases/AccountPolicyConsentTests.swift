import Foundation
import Testing

@testable import DomainAccount

@Suite("Account 약관 동의·탈퇴")
struct AccountPolicyConsentTests {

    // MARK: Internal

    @Test
    func `필수 약관마다 같은 버전의 동의가 있으면 충족한다`() async throws {
        let consents = [
            PolicyConsent(documentID: "terms", version: "1", consentedAt: Self.consentedAt),
            PolicyConsent(documentID: "privacy", version: "1", consentedAt: Self.consentedAt),
        ]
        let account = Self.makeAccount(policyConsentRepository: InMemoryPolicyConsentRepository(consents: consents))

        let status = try await account.policyConsentStatus()

        #expect(status.isSatisfied)
        #expect(status.documents == Self.documents)
        #expect(status.consents == consents)
    }

    @Test
    func `필수 약관 버전이 바뀌면 이전 동의로는 충족하지 않는다`() async throws {
        let consents = [
            PolicyConsent(documentID: "terms", version: "1", consentedAt: Self.consentedAt),
            PolicyConsent(documentID: "privacy", version: "0", consentedAt: Self.consentedAt),
        ]
        let account = Self.makeAccount(policyConsentRepository: InMemoryPolicyConsentRepository(consents: consents))

        #expect(try await account.policyConsentStatus().isSatisfied == false)
    }

    @Test
    func `동의한 문서의 현재 버전과 동의 시각을 기록한다`() async throws {
        let repository = InMemoryPolicyConsentRepository()
        let account = Self.makeAccount(policyConsentRepository: repository)

        try await account.consent(to: ["terms", "marketing"])

        #expect(await repository.storedConsents == [
            PolicyConsent(documentID: "terms", version: "1", consentedAt: Self.consentedAt),
            PolicyConsent(documentID: "marketing", version: "2", consentedAt: Self.consentedAt),
        ])
    }

    @Test
    func `탈퇴하면 동의 기록을 지우고 signedOut 상태를 방출한다`() async throws {
        let repository = InMemoryPolicyConsentRepository(consents: [
            PolicyConsent(documentID: "terms", version: "1", consentedAt: Self.consentedAt)
        ])
        let account = Self.makeAccount(policyConsentRepository: repository)
        var states = await account.signInStates().makeAsyncIterator()
        _ = await states.next()

        try await account.withdraw()

        #expect(await repository.removeAllCount == 1)
        let state = await states.next()
        #expect(state == .signedOut)
    }

    @Test
    func `탈퇴 요청이 실패하면 오류를 전달하고 동의 기록을 유지한다`() async {
        let repository = InMemoryPolicyConsentRepository()
        let account = Self.makeAccount(
            withdrawalRepository: StubWithdrawalRepository(error: .withdrawalUnavailable),
            policyConsentRepository: repository,
        )

        await #expect(throws: AccountError.withdrawalUnavailable) {
            try await account.withdraw()
        }
        #expect(await repository.removeAllCount == 0)
    }

    // MARK: Private

    private static let consentedAt = Date(timeIntervalSince1970: 1_000)

    private static let documents = [
        PolicyDocument(
            id: "terms",
            displayName: "이용약관",
            version: "1",
            approvedURL: URL(string: "https://example.com/terms")!,
            isRequired: true,
        ),
        PolicyDocument(
            id: "privacy",
            displayName: "개인정보 처리방침",
            version: "1",
            approvedURL: URL(string: "https://example.com/privacy")!,
            isRequired: true,
        ),
        PolicyDocument(
            id: "marketing",
            displayName: "마케팅 수신 동의",
            version: "2",
            approvedURL: URL(string: "https://example.com/marketing")!,
            isRequired: false,
        ),
    ]

    private static func makeAccount(
        withdrawalRepository: StubWithdrawalRepository = StubWithdrawalRepository(),
        policyConsentRepository: InMemoryPolicyConsentRepository,
    ) -> Account {
        Account(
            authenticationRepository: StubAuthenticationRepository(),
            signInRepository: StubSignInRepository(),
            withdrawalRepository: withdrawalRepository,
            policyConsentRepository: policyConsentRepository,
            policyDocuments: documents,
            signInInvalidations: { AsyncStream { _ in } },
            now: { consentedAt },
        )
    }

}
