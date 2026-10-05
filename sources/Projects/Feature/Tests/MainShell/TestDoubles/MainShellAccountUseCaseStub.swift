import DomainUseCaseInterface

actor MainShellAccountUseCaseStub: AccountUseCase {

    // MARK: Lifecycle

    init(
        signInResults: [SignInResult] = [.retryableFailure],
        consentStatus: PolicyConsentStatus = PolicyConsentStatus(
            documents: [],
            consents: [],
            isSatisfied: false,
        ),
    ) {
        self.signInResults = signInResults
        self.consentStatus = consentStatus
    }

    // MARK: Internal

    func signIn(with method: SignInMethod) async -> SignInResult {
        signInMethods.append(method)
        guard !signInResults.isEmpty else { return .retryableFailure }
        return signInResults.count > 1 ? signInResults.removeFirst() : signInResults[0]
    }

    func signOut() async -> SignOutResult {
        .signedOut
    }

    func signInStates() async -> AsyncStream<SignInState> {
        AsyncStream { $0.finish() }
    }

    func restoreSignIn() async -> SignInRestoration {
        .signedOut
    }

    func verifySignIn() async -> SignInVerification {
        .valid
    }

    func signInAvailability() async -> SignInAvailability {
        .signedIn
    }

    func policyConsentStatus() async throws -> PolicyConsentStatus {
        consentStatusCallCount += 1
        return consentStatus
    }

    func consent(to documentIDs: [PolicyDocumentID]) async throws {
        consentedDocumentIDs.append(documentIDs)
    }

    func withdraw() async throws { }

    func snapshot() -> (signInMethods: [SignInMethod], consentStatusCallCount: Int, consentedDocumentIDs: [[PolicyDocumentID]]) {
        (signInMethods, consentStatusCallCount, consentedDocumentIDs)
    }

    // MARK: Private

    private var signInResults: [SignInResult]
    private let consentStatus: PolicyConsentStatus
    private var signInMethods = [SignInMethod]()
    private var consentStatusCallCount = 0
    private var consentedDocumentIDs = [[PolicyDocumentID]]()

}
