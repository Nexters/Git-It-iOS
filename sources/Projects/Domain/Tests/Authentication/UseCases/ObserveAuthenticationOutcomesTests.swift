import Testing

@testable import DomainAuthentication

// MARK: - ObserveAuthenticationOutcomesTests

@Suite("ObserveAuthenticationOutcomes")
struct ObserveAuthenticationOutcomesTests {
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
        let loginSessionRepository = AuthorizationChangesLoginSessionRepository(
            restoredUser: user,
            recorder: recorder,
        )
        let observeAuthenticationOutcomes = ObserveAuthenticationOutcomes(
            authenticationRepository: authenticationRepository,
            loginSessionRepository: loginSessionRepository,
        )

        var outcomes = [AuthenticationOutcome]()
        for await outcome in await observeAuthenticationOutcomes() {
            outcomes.append(outcome)
        }

        #expect(outcomes == [.authenticated(user), .recoverableFailure, .unauthenticated])
        #expect(
            await recorder.snapshot() == [
                .authorizationChanges,
                .restore,
                .signOut,
                .clearAuthentication,
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
        case clearAuthentication
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
        statuses: [AuthorizationStatus],
        recorder: AuthorizationChangesCallRecorder,
    ) {
        self.statuses = statuses
        self.recorder = recorder
    }

    // MARK: Internal

    func authenticate(using _: AuthenticationMethod) async throws -> AuthenticationGrant {
        throw AuthenticationError.temporarilyUnavailable
    }

    func authorizationStatus() async throws -> AuthorizationStatus {
        .authorized
    }

    func authorizationChanges() async -> AsyncStream<AuthorizationStatus> {
        await recorder.append(.authorizationChanges)
        let statuses = statuses

        return AsyncStream { continuation in
            for status in statuses {
                continuation.yield(status)
            }
            continuation.finish()
        }
    }

    func clearAuthentication() async throws {
        await recorder.append(.clearAuthentication)
    }

    // MARK: Private

    private let recorder: AuthorizationChangesCallRecorder
    private let statuses: [AuthorizationStatus]

}

// MARK: - AuthorizationChangesLoginSessionRepository

private actor AuthorizationChangesLoginSessionRepository: LoginSessionRepository {

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
