public struct RestoreSession: RestoreSessionUseCase, Sendable {

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
        let user: AuthenticatedUser

        do {
            guard let restoredUser = try await loginSessionRepository.restore()
            else {
                await clearAuthentication()
                return .unauthenticated
            }
            user = restoredUser
        } catch let error as LoginSessionError {
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
    private let loginSessionRepository: any LoginSessionRepository

    private func outcome(for error: LoginSessionError) async -> AuthenticationOutcome {
        switch error {
        case .temporarilyUnavailable:
            return .recoverableFailure

        case .refreshRejectedOrExpired,
             .accountUnavailable,
             .unauthorized:
            await clearInvalidSession()
            return .unauthenticated
        }
    }

    private func clearInvalidSession() async {
        do {
            try await loginSessionRepository.signOut()
        } catch { }
        await clearAuthentication()
    }

    private func clearAuthentication() async {
        do {
            try await authenticationRepository.clearAuthentication()
        } catch { }
    }

}
