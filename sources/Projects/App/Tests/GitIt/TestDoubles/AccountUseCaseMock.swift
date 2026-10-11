import DomainUseCaseInterface
import Foundation

actor AccountUseCaseMock: AccountUseCase {

    // MARK: Lifecycle

    init(
        restorations: [SignInRestoration] = [.signedOut],
        verification: SignInVerification = .valid,
        signOutResults: [SignOutResult] = [.signedOut],
    ) {
        self.restorations = restorations
        self.verification = verification
        self.signOutResults = signOutResults
    }

    // MARK: Internal

    private(set) var restoreCallCount = 0
    private(set) var signOutCallCount = 0
    private(set) var verifyCallCount = 0

    func signIn(with _: SignInMethod) async -> SignInResult {
        .retryableFailure
    }

    func signOut() async -> SignOutResult {
        signOutCallCount += 1
        guard !signOutResults.isEmpty else { return .signedOut }
        return signOutResults.count > 1 ? signOutResults.removeFirst() : signOutResults[0]
    }

    func signInStates() async -> AsyncStream<SignInState> {
        AsyncStream { $0.finish() }
    }

    func restoreSignIn() async -> SignInRestoration {
        restoreCallCount += 1
        guard !restorations.isEmpty else { return .temporarilyUnavailable }
        return restorations.count > 1 ? restorations.removeFirst() : restorations[0]
    }

    func verifySignIn() async -> SignInVerification {
        verifyCallCount += 1
        return verification
    }

    func signInAvailability() async -> SignInAvailability {
        .signInRequired
    }

    func policyConsentStatus() async throws -> PolicyConsentStatus {
        PolicyConsentStatus(
            documents: [],
            consents: [],
            isSatisfied: true,
        )
    }

    func consent(to _: [PolicyDocumentID]) async throws { }

    func withdraw() async throws {
        throw AccountError.withdrawalUnavailable
    }

    // MARK: Private

    private var restorations: [SignInRestoration]
    private let verification: SignInVerification
    private var signOutResults: [SignOutResult]

}
