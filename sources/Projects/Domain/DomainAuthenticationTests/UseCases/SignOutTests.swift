import Testing

@testable import DomainAuthentication

// MARK: - SignOutTests

@Suite("SignOut")
struct SignOutTests {
    @Test
    func `서버 세션을 먼저 종료한 뒤 인증 참조를 정리한다`() async {
        let recorder = SignOutCallRecorder()
        let signOut = SignOut(
            authenticationRepository: SignOutAuthenticationRepository(
                shouldFail: false,
                recorder: recorder,
            ),
            sessionRepository: SignOutSessionRepository(
                shouldFail: false,
                recorder: recorder,
            ),
        )

        let outcome = await signOut()

        #expect(outcome == .unauthenticated)
        #expect(await recorder.snapshot() == [.signOut, .clearAuthorization])
    }

    @Test
    func `원격 폐기 실패와 관계없이 인증 참조를 정리하고 로그아웃한다`() async {
        let recorder = SignOutCallRecorder()
        let signOut = SignOut(
            authenticationRepository: SignOutAuthenticationRepository(
                shouldFail: true,
                recorder: recorder,
            ),
            sessionRepository: SignOutSessionRepository(
                shouldFail: true,
                recorder: recorder,
            ),
        )

        let outcome = await signOut()

        #expect(outcome == .unauthenticated)
        #expect(await recorder.snapshot() == [.signOut, .clearAuthorization])
    }
}

// MARK: - SignOutCallRecorder

private actor SignOutCallRecorder {

    // MARK: Internal

    enum Call: Equatable, Sendable {
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

// MARK: - SignOutAuthenticationRepository

private actor SignOutAuthenticationRepository: AuthenticationRepository {

    // MARK: Lifecycle

    init(
        shouldFail: Bool,
        recorder: SignOutCallRecorder,
    ) {
        self.shouldFail = shouldFail
        self.recorder = recorder
    }

    // MARK: Internal

    func authenticate(using _: AuthenticationMethod) async throws -> AuthenticationGrant {
        throw AuthenticationError.temporarilyUnavailable
    }

    func authorizationStatus() async throws -> AuthenticationAuthorizationStatus {
        .temporarilyUnavailable
    }

    func authorizationChanges() async -> AsyncStream<AuthenticationAuthorizationStatus> {
        AsyncStream { $0.finish() }
    }

    func clearAuthorization() async throws {
        await recorder.append(.clearAuthorization)
        if shouldFail {
            throw AuthenticationError.temporarilyUnavailable
        }
    }

    // MARK: Private

    private let recorder: SignOutCallRecorder
    private let shouldFail: Bool

}

// MARK: - SignOutSessionRepository

private actor SignOutSessionRepository: SessionRepository {

    // MARK: Lifecycle

    init(
        shouldFail: Bool,
        recorder: SignOutCallRecorder,
    ) {
        self.shouldFail = shouldFail
        self.recorder = recorder
    }

    // MARK: Internal

    func start(with _: AuthenticationGrant) async throws -> AuthenticatedUser {
        throw SessionError.temporarilyUnavailable
    }

    func restore() async throws -> AuthenticatedUser? {
        nil
    }

    func signOut() async throws {
        await recorder.append(.signOut)
        if shouldFail {
            throw SessionError.temporarilyUnavailable
        }
    }

    // MARK: Private

    private let recorder: SignOutCallRecorder
    private let shouldFail: Bool

}
