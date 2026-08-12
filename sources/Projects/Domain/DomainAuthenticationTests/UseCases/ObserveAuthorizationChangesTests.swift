import Testing

@testable import DomainAuthentication

// MARK: - ObserveAuthorizationChangesTests

@Suite("ObserveAuthorizationChanges")
struct ObserveAuthorizationChangesTests {
    @Test
    func `authorization 변경을 저장 정리와 인증 결과로 수렴한다`() async {
        let recorder = AuthorizationChangesCallRecorder()
        let user = AuthenticatedUser(
            id: "user-1",
            availability: .available,
            displayName: nil,
        )
        let authenticationRepository = AuthorizationChangesAuthenticationRepository(
            statuses: [.authorized, .temporarilyUnavailable, .reauthenticationRequired],
            recorder: recorder,
        )
        let sessionRepository = AuthorizationChangesSessionRepository(
            restoredUser: user,
            recorder: recorder,
        )
        let observeAuthorizationChanges = ObserveAuthorizationChanges(
            authenticationRepository: authenticationRepository,
            sessionRepository: sessionRepository,
        )

        var outcomes = [AuthenticationOutcome]()
        for await outcome in await observeAuthorizationChanges() {
            outcomes.append(outcome)
        }

        #expect(outcomes == [.authenticated(user), .recoverableFailure, .unauthenticated])
        #expect(
            await recorder.snapshot() == [
                .authorizationChanges,
                .restore,
                .signOut,
                .clearAuthorization,
            ]
        )
    }
}

// MARK: - AuthorizationChangesCallRecorder

private actor AuthorizationChangesCallRecorder {

    // MARK: Internal

    enum Call: Equatable, Sendable {
        case authorizationChanges
        case restore
        case signOut
        case clearAuthorization
    }

    func append(_ call: Call) {
        calls.append(call)
    }

    func snapshot() -> [Call] {
        calls
    }

    // MARK: Private

    private var calls = [Call]()

}

// MARK: - AuthorizationChangesAuthenticationRepository

private actor AuthorizationChangesAuthenticationRepository: AuthenticationRepository {

    // MARK: Lifecycle

    init(
        statuses: [AuthenticationAuthorizationStatus],
        recorder: AuthorizationChangesCallRecorder,
    ) {
        self.statuses = statuses
        self.recorder = recorder
    }

    // MARK: Internal

    func authenticate(using _: AuthenticationMethod) async throws -> AuthenticationGrant {
        throw AuthenticationError.temporarilyUnavailable
    }

    func authorizationStatus() async throws -> AuthenticationAuthorizationStatus {
        .authorized
    }

    func authorizationChanges() async -> AsyncStream<AuthenticationAuthorizationStatus> {
        await recorder.append(.authorizationChanges)
        let statuses = statuses

        return AsyncStream { continuation in
            for status in statuses {
                continuation.yield(status)
            }
            continuation.finish()
        }
    }

    func clearAuthorization() async throws {
        await recorder.append(.clearAuthorization)
    }

    // MARK: Private

    private let recorder: AuthorizationChangesCallRecorder
    private let statuses: [AuthenticationAuthorizationStatus]

}

// MARK: - AuthorizationChangesSessionRepository

private actor AuthorizationChangesSessionRepository: SessionRepository {

    // MARK: Lifecycle

    init(
        restoredUser: AuthenticatedUser,
        recorder: AuthorizationChangesCallRecorder,
    ) {
        self.restoredUser = restoredUser
        self.recorder = recorder
    }

    // MARK: Internal

    func start(with _: AuthenticationGrant) async throws -> AuthenticatedUser {
        restoredUser
    }

    func restore() async throws -> AuthenticatedUser? {
        await recorder.append(.restore)
        return restoredUser
    }

    func signOut() async throws {
        await recorder.append(.signOut)
    }

    // MARK: Private

    private let recorder: AuthorizationChangesCallRecorder
    private let restoredUser: AuthenticatedUser

}
