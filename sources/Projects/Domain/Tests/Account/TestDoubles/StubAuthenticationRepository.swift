import DomainUseCaseDependency
@testable import DomainUseCaseInterface

actor StubAuthenticationRepository: AuthenticationRepository {

    // MARK: Lifecycle

    init(
        authenticateResult: Result<AuthenticationGrant, AccountError> = .success(
            AuthenticationGrant(
                id: "grant-1",
                method: .apple,
            )
        ),
        authorizationResult: Result<SignInVerification, AccountError> = .success(.valid),
    ) {
        self.authenticateResult = authenticateResult
        self.authorizationResult = authorizationResult
    }

    // MARK: Internal

    private(set) var clearAuthenticationCount = 0

    func authenticate(using _: SignInMethod) async throws -> AuthenticationGrant {
        try authenticateResult.get()
    }

    func authorizationStatus() async throws -> SignInVerification {
        try authorizationResult.get()
    }

    func clearAuthentication() async throws {
        clearAuthenticationCount += 1
    }

    // MARK: Private

    private let authenticateResult: Result<AuthenticationGrant, AccountError>
    private let authorizationResult: Result<SignInVerification, AccountError>

}
