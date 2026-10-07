import Foundation

// MARK: - ResolveSessionAvailability

public struct ResolveSessionAvailability: ResolveSessionAvailabilityUseCase {

    // MARK: Lifecycle

    public init(
        markerRepository: any SharedSessionMarkerRepository,
        sessionRepository: any StoredSessionRepository,
        now: @escaping @Sendable () -> Date = { Date() },
    ) {
        self.markerRepository = markerRepository
        self.sessionRepository = sessionRepository
        self.now = now
    }

    // MARK: Public

    public func callAsFunction() async -> SessionAvailability {
        guard let isSignedIn = await markerRepository.signedInState() else {
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

    private let markerRepository: any SharedSessionMarkerRepository
    private let sessionRepository: any StoredSessionRepository
    private let now: @Sendable () -> Date

}
