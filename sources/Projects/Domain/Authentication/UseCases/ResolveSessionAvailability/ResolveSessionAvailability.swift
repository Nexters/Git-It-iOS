import Foundation

// MARK: - ResolveSessionAvailability

public struct ResolveSessionAvailability: ResolveSessionAvailabilityUseCase {

    // MARK: Lifecycle

    public init(
        signInStateRepository: any SharedSignInStateRepository,
        sessionRepository: any CurrentSessionRepository,
        now: @escaping @Sendable () -> Date = { Date() },
    ) {
        self.signInStateRepository = signInStateRepository
        self.sessionRepository = sessionRepository
        self.now = now
    }

    // MARK: Public

    public func callAsFunction() async -> SessionAvailability {
        guard let isSignedIn = await signInStateRepository.signedInState() else {
            return .appLaunchRequired
        }
        guard isSignedIn else { return .signInRequired }
        guard
            let record = await sessionRepository.currentSession(),
            !record.tokens.accessToken.isEmpty
        else { return .signInRequired }
        if
            let expiresAt = record.tokens.accessTokenExpiresAt,
            expiresAt <= now()
        {
            return .signInRequired
        }
        return .available(accessToken: record.tokens.accessToken)
    }

    // MARK: Private

    private let signInStateRepository: any SharedSignInStateRepository
    private let sessionRepository: any CurrentSessionRepository
    private let now: @Sendable () -> Date

}
