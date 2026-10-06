public struct AuthenticationOutcomes: AuthenticationOutcomesUseCase, Sendable {

    // MARK: Lifecycle

    public init(
        authenticationRepository: any AuthenticationRepository,
        loginSessionRepository: any LoginSessionRepository,
    ) {
        self.authenticationRepository = authenticationRepository
        self.loginSessionRepository = loginSessionRepository
    }

    // MARK: Public

    public func callAsFunction() async -> AsyncStream<AuthenticationOutcome> {
        let authorizationChanges = await authenticationRepository.authorizationChanges()

        return AsyncStream { continuation in
            let task = Task {
                for await status in authorizationChanges {
                    guard !Task.isCancelled else { break }
                    continuation.yield(await outcome(for: status))
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: Private

    private let authenticationRepository: any AuthenticationRepository
    private let loginSessionRepository: any LoginSessionRepository

    private func outcome(
        for status: AuthorizationStatus
    ) async -> AuthenticationOutcome {
        switch status {
        case .authorized:
            return await restoreAuthorizedSession()

        case .reauthenticationRequired:
            await clearInvalidSession()
            return .unauthenticated

        case .temporarilyUnavailable:
            return .recoverableFailure
        }
    }

    private func restoreAuthorizedSession() async -> AuthenticationOutcome {
        do {
            guard let user = try await loginSessionRepository.restore()
            else {
                await clearAuthentication()
                return .unauthenticated
            }

            guard user.availability == .available
            else {
                await clearInvalidSession()
                return .unauthenticated
            }

            return .authenticated(user)
        } catch let error as LoginSessionError {
            switch error {
            case .temporarilyUnavailable:
                return .recoverableFailure

            case .refreshRejectedOrExpired,
                 .accountUnavailable,
                 .unauthorized:
                await clearInvalidSession()
                return .unauthenticated
            }
        } catch {
            return .recoverableFailure
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
