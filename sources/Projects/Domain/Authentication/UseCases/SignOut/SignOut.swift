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

    public func callAsFunction() async -> SignOutResult {
        do {
            try await loginSessionRepository.signOut()
        } catch {
            return .retryableFailure
        }

        do {
            try await authenticationRepository.clearAuthentication()
        } catch {
            return .retryableFailure
        }

        return .success
    }

    // MARK: Private

    private let authenticationRepository: any AuthenticationRepository
    private let loginSessionRepository: any LoginSessionRepository

}
