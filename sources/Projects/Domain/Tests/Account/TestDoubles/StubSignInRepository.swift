@testable import DomainAccount

actor StubSignInRepository: SignInRepository {

    // MARK: Lifecycle

    init(
        startResult: Result<SignInRecord, AccountError> = .success(StubSignInRepository.availableRecord),
        restoreResult: Result<SignInRecord?, AccountError> = .success(StubSignInRepository.availableRecord),
        signOutError: AccountError? = nil,
        sharedSignInState: Bool? = true,
        hasUsableCredential: Bool = true,
    ) {
        self.startResult = startResult
        self.restoreResult = restoreResult
        self.signOutError = signOutError
        storedSharedSignInState = sharedSignInState
        storedHasUsableCredential = hasUsableCredential
    }

    // MARK: Internal

    static let account = SignedInAccount(
        id: "account-1",
        displayName: "Git It",
        needsCuration: true,
    )
    static let availableRecord = SignInRecord(
        account: account,
        isAccountAvailable: true,
    )

    private(set) var signOutCount = 0

    func start(with _: AuthenticationGrant) async throws -> SignInRecord {
        try startResult.get()
    }

    func restore() async throws -> SignInRecord? {
        try restoreResult.get()
    }

    func signOut() async throws {
        signOutCount += 1
        if let signOutError {
            throw signOutError
        }
    }

    func sharedSignInState() async -> Bool? {
        storedSharedSignInState
    }

    func hasUsableCredential() async -> Bool {
        storedHasUsableCredential
    }

    // MARK: Private

    private let startResult: Result<SignInRecord, AccountError>
    private let restoreResult: Result<SignInRecord?, AccountError>
    private let signOutError: AccountError?
    private let storedSharedSignInState: Bool?
    private let storedHasUsableCredential: Bool

}
