
public struct SignOut: Sendable {

    // MARK: Lifecycle

    public init(
        authenticationRepository: any AuthenticationRepository,
        sessionRepository: any SessionRepository,
    ) {
        self.authenticationRepository = authenticationRepository
        self.sessionRepository = sessionRepository
    }

    // MARK: Public

    public func callAsFunction() async -> AuthenticationOutcome {
        do {
            try await sessionRepository.signOut()
        } catch { }

        do {
            try await authenticationRepository.clearAuthorization()
        } catch { }

        return .unauthenticated
    }

    // MARK: Private

    private let authenticationRepository: any AuthenticationRepository
    private let sessionRepository: any SessionRepository

}
