public struct RestoreSession: Sendable {

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
        let user: AuthenticatedUser

        do {
            guard let restoredUser = try await sessionRepository.restore()
            else {
                await clearAuthorization()
                return .unauthenticated
            }
            user = restoredUser
        } catch let error as SessionError {
            return await outcome(for: error)
        } catch {
            return .recoverableFailure
        }

        guard user.availability == .available
        else {
            await clearInvalidSession()
            return .unauthenticated
        }

        do {
            switch try await authenticationRepository.authorizationStatus() {
            case .authorized:
                return .authenticated(user)

            case .reauthenticationRequired:
                await clearInvalidSession()
                return .unauthenticated

            case .temporarilyUnavailable:
                return .recoverableFailure
            }
        } catch {
            return .recoverableFailure
        }
    }

    // MARK: Private

    private let authenticationRepository: any AuthenticationRepository
    private let sessionRepository: any SessionRepository

    private func outcome(for error: SessionError) async -> AuthenticationOutcome {
        switch error {
        case .temporarilyUnavailable:
            return .recoverableFailure

        case .refreshRejectedOrExpired,
             .accountUnavailable:
            await clearInvalidSession()
            return .unauthenticated
        }
    }

    private func clearInvalidSession() async {
        do {
            try await sessionRepository.signOut()
        } catch { }
        await clearAuthorization()
    }

    private func clearAuthorization() async {
        do {
            try await authenticationRepository.clearAuthorization()
        } catch { }
    }

}
