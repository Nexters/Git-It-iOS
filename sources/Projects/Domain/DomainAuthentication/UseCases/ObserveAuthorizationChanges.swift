public struct ObserveAuthorizationChanges: Sendable {

    // MARK: Lifecycle

    public init(
        authenticationRepository: any AuthenticationRepository,
        sessionRepository: any SessionRepository,
    ) {
        self.authenticationRepository = authenticationRepository
        self.sessionRepository = sessionRepository
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
    private let sessionRepository: any SessionRepository

    private func outcome(
        for status: AuthenticationAuthorizationStatus
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
            guard let user = try await sessionRepository.restore()
            else {
                await clearAuthorization()
                return .unauthenticated
            }

            guard user.availability == .available
            else {
                await clearInvalidSession()
                return .unauthenticated
            }

            return .authenticated(user)
        } catch let error as SessionError {
            switch error {
            case .temporarilyUnavailable:
                return .recoverableFailure

            case .refreshRejectedOrExpired,
                 .accountUnavailable:
                await clearInvalidSession()
                return .unauthenticated
            }
        } catch {
            return .recoverableFailure
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
