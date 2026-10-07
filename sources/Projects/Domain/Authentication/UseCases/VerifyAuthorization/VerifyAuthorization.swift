public struct VerifyAuthorization: VerifyAuthorizationUseCase, Sendable {

    // MARK: Lifecycle

    public init(
        authenticationRepository: any AuthenticationRepository,
        loginSessionRepository: any LoginSessionRepository,
    ) {
        self.authenticationRepository = authenticationRepository
        self.loginSessionRepository = loginSessionRepository
    }

    // MARK: Public

    public func callAsFunction() async -> AuthorizationStatus {
        guard let status = try? await authenticationRepository.authorizationStatus() else {
            return .temporarilyUnavailable
        }
        guard status == .reauthenticationRequired else { return status }
        await clearInvalidSession()
        return status
    }

    // MARK: Private

    private let authenticationRepository: any AuthenticationRepository
    private let loginSessionRepository: any LoginSessionRepository

    private func clearInvalidSession() async {
        do {
            try await loginSessionRepository.signOut()
        } catch { }
        do {
            try await authenticationRepository.clearAuthentication()
        } catch { }
    }

}
