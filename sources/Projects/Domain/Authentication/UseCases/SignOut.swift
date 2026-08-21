public struct SignOut: SignOutUseCase, Sendable {

    // MARK: Lifecycle

    public init(
        authenticationRepository: any AuthenticationRepository,
        loginSessionRepository: any LoginSessionRepository,
    ) {
        self.authenticationRepository = authenticationRepository
        self.loginSessionRepository = loginSessionRepository
    }

    // MARK: Public

    public func callAsFunction() async -> AuthenticationOutcome {
        do {
            try await loginSessionRepository.signOut()
        } catch { }

        do {
            try await authenticationRepository.clearAuthentication()
        } catch { }

        return .unauthenticated
    }

    // MARK: Private

    private let authenticationRepository: any AuthenticationRepository
    private let loginSessionRepository: any LoginSessionRepository

}
