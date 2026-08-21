public struct SignIn: SignInUseCase, Sendable {

    // MARK: Lifecycle

    public init(
        authenticationRepository: any AuthenticationRepository,
        loginSessionRepository: any LoginSessionRepository,
    ) {
        self.authenticationRepository = authenticationRepository
        self.loginSessionRepository = loginSessionRepository
    }

    // MARK: Public

    public func callAsFunction(_ method: AuthenticationMethod) async -> AuthenticationOutcome {
        let grant: AuthenticationGrant

        do {
            grant = try await authenticationRepository.authenticate(using: method)
        } catch AuthenticationError.cancelled {
            return .unauthenticated
        } catch {
            return .recoverableFailure
        }

        do {
            let user = try await loginSessionRepository.start(with: grant)
            return .authenticated(user)
        } catch let error as LoginSessionError {
            await clearAuthentication()

            switch error {
            case .temporarilyUnavailable:
                return .recoverableFailure

            case .refreshRejectedOrExpired,
                 .accountUnavailable,
                 .unauthorized:
                return .unauthenticated
            }
        } catch {
            await clearAuthentication()
            return .recoverableFailure
        }
    }

    // MARK: Private

    private let authenticationRepository: any AuthenticationRepository
    private let loginSessionRepository: any LoginSessionRepository

    private func clearAuthentication() async {
        do {
            try await authenticationRepository.clearAuthentication()
        } catch { }
    }

}
