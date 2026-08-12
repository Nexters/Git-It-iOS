
public struct SignIn: Sendable {

    // MARK: Lifecycle

    public init(
        authenticationRepository: any AuthenticationRepository,
        sessionRepository: any SessionRepository,
    ) {
        self.authenticationRepository = authenticationRepository
        self.sessionRepository = sessionRepository
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
            let user = try await sessionRepository.start(with: grant)
            return .authenticated(user)
        } catch let error as SessionError {
            await clearAuthorization()

            switch error {
            case .temporarilyUnavailable:
                return .recoverableFailure

            case .refreshRejectedOrExpired,
                 .accountUnavailable:
                return .unauthenticated
            }
        } catch {
            await clearAuthorization()
            return .recoverableFailure
        }
    }

    // MARK: Private

    private let authenticationRepository: any AuthenticationRepository
    private let sessionRepository: any SessionRepository

    private func clearAuthorization() async {
        do {
            try await authenticationRepository.clearAuthorization()
        } catch { }
    }

}
