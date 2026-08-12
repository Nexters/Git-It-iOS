import Testing

@testable import DomainAuthentication

// MARK: - RestoreSessionTests

@Suite("RestoreSession")
struct RestoreSessionTests {
    @Test
    func `저장된 세션이 없으면 남은 인증 참조를 정리한다`() async {
        let recorder = RestoreSessionCallRecorder()
        let restoreSession = makeRestoreSession(
            sessionBehavior: .missing,
            authorizationStatus: .authorized,
            recorder: recorder,
        )

        let outcome = await restoreSession()

        #expect(outcome == .unauthenticated)
        #expect(await recorder.snapshot() == [.restore, .clearAuthorization])
    }

    @Test
    func `세션과 authorization이 유효하면 인증 사용자로 복원한다`() async {
        let recorder = RestoreSessionCallRecorder()
        let user = AuthenticatedUser(
            id: "user-1",
            availability: .available,
            displayName: nil,
        )
        let restoreSession = makeRestoreSession(
            sessionBehavior: .restored(user),
            authorizationStatus: .authorized,
            recorder: recorder,
        )

        let outcome = await restoreSession()

        #expect(outcome == .authenticated(user))
        #expect(await recorder.snapshot() == [.restore, .authorizationStatus])
    }

    @Test
    func `authorization 조회 일시 실패는 저장 상태를 유지한다`() async {
        let recorder = RestoreSessionCallRecorder()
        let user = AuthenticatedUser(
            id: "user-1",
            availability: .available,
            displayName: nil,
        )
        let restoreSession = makeRestoreSession(
            sessionBehavior: .restored(user),
            authorizationStatus: .temporarilyUnavailable,
            recorder: recorder,
        )

        let outcome = await restoreSession()

        #expect(outcome == .recoverableFailure)
        #expect(await recorder.snapshot() == [.restore, .authorizationStatus])
    }

    @Test
    func `재인증이 필요하면 세션과 인증 참조를 순서대로 정리한다`() async {
        let recorder = RestoreSessionCallRecorder()
        let user = AuthenticatedUser(
            id: "user-1",
            availability: .available,
            displayName: nil,
        )
        let restoreSession = makeRestoreSession(
            sessionBehavior: .restored(user),
            authorizationStatus: .reauthenticationRequired,
            recorder: recorder,
        )

        let outcome = await restoreSession()

        #expect(outcome == .unauthenticated)
        #expect(
            await recorder.snapshot() == [
                .restore,
                .authorizationStatus,
                .signOut,
                .clearAuthorization,
            ]
        )
    }

    @Test
    func `refresh 일시 실패는 저장 상태를 유지하고 재시도를 허용한다`() async {
        let recorder = RestoreSessionCallRecorder()
        let restoreSession = makeRestoreSession(
            sessionBehavior: .fail(.temporarilyUnavailable),
            authorizationStatus: .authorized,
            recorder: recorder,
        )

        let outcome = await restoreSession()

        #expect(outcome == .recoverableFailure)
        #expect(await recorder.snapshot() == [.restore])
    }

    @Test
    func `refresh 거부 또는 만료는 세션과 인증 참조를 정리한다`() async {
        let recorder = RestoreSessionCallRecorder()
        let restoreSession = makeRestoreSession(
            sessionBehavior: .fail(.refreshRejectedOrExpired),
            authorizationStatus: .authorized,
            recorder: recorder,
        )

        let outcome = await restoreSession()

        #expect(outcome == .unauthenticated)
        #expect(await recorder.snapshot() == [.restore, .signOut, .clearAuthorization])
    }
}

extension RestoreSessionTests {
    private func makeRestoreSession(
        sessionBehavior: RestoreSessionSessionRepository.Behavior,
        authorizationStatus: AuthenticationAuthorizationStatus,
        recorder: RestoreSessionCallRecorder,
    ) -> RestoreSession {
        RestoreSession(
            authenticationRepository: RestoreSessionAuthenticationRepository(
                status: authorizationStatus,
                recorder: recorder,
            ),
            sessionRepository: RestoreSessionSessionRepository(
                behavior: sessionBehavior,
                recorder: recorder,
            ),
        )
    }
}

// MARK: - RestoreSessionCallRecorder

private actor RestoreSessionCallRecorder {

    // MARK: Internal

    enum Call: Equatable, Sendable {
        case restore
        case authorizationStatus
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

// MARK: - RestoreSessionAuthenticationRepository

private actor RestoreSessionAuthenticationRepository: AuthenticationRepository {

    // MARK: Lifecycle

    init(
        status: AuthenticationAuthorizationStatus,
        recorder: RestoreSessionCallRecorder,
    ) {
        self.status = status
        self.recorder = recorder
    }

    // MARK: Internal

    func authenticate(using _: AuthenticationMethod) async throws -> AuthenticationGrant {
        throw AuthenticationError.temporarilyUnavailable
    }

    func authorizationStatus() async throws -> AuthenticationAuthorizationStatus {
        await recorder.append(.authorizationStatus)
        return status
    }

    func authorizationChanges() async -> AsyncStream<AuthenticationAuthorizationStatus> {
        AsyncStream { $0.finish() }
    }

    func clearAuthorization() async throws {
        await recorder.append(.clearAuthorization)
    }

    // MARK: Private

    private let recorder: RestoreSessionCallRecorder
    private let status: AuthenticationAuthorizationStatus

}

// MARK: - RestoreSessionSessionRepository

private actor RestoreSessionSessionRepository: SessionRepository {

    // MARK: Lifecycle

    init(
        behavior: Behavior,
        recorder: RestoreSessionCallRecorder,
    ) {
        self.behavior = behavior
        self.recorder = recorder
    }

    // MARK: Internal

    enum Behavior: Sendable {
        case missing
        case restored(AuthenticatedUser)
        case fail(SessionError)
    }

    func start(with _: AuthenticationGrant) async throws -> AuthenticatedUser {
        throw SessionError.temporarilyUnavailable
    }

    func restore() async throws -> AuthenticatedUser? {
        await recorder.append(.restore)

        switch behavior {
        case .missing:
            return nil

        case .restored(let user):
            return user

        case .fail(let error):
            throw error
        }
    }

    func signOut() async throws {
        await recorder.append(.signOut)
    }

    // MARK: Private

    private let behavior: Behavior
    private let recorder: RestoreSessionCallRecorder

}
