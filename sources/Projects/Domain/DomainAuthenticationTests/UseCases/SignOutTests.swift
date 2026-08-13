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
            loginSessionRepository: SignOutLoginSessionRepository(
                shouldFail: false,
                recorder: recorder,
            ),
        )

        let outcome = await signOut()

        #expect(outcome == .unauthenticated)
        #expect(await recorder.snapshot() == [.signOut, .clearAuthentication])
    }

    @Test
    func `원격 폐기 실패와 관계없이 인증 참조를 정리하고 로그아웃한다`() async {
        let recorder = SignOutCallRecorder()
        let signOut = SignOut(
            authenticationRepository: SignOutAuthenticationRepository(
                shouldFail: true,
                recorder: recorder,
            ),
            loginSessionRepository: SignOutLoginSessionRepository(
                shouldFail: true,
                recorder: recorder,
            ),
        )

        let outcome = await signOut()

        #expect(outcome == .unauthenticated)
        #expect(await recorder.snapshot() == [.signOut, .clearAuthentication])
    }
}

// MARK: - SignOutCallRecorder

private actor SignOutCallRecorder {

    // MARK: Internal

    enum Call: Equatable, Sendable {
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

    func authorizationStatus() async throws -> AuthorizationStatus {
        .temporarilyUnavailable
    }

    func authorizationChanges() async -> AsyncStream<AuthorizationStatus> {
        AsyncStream { $0.finish() }
    }

    func clearAuthentication() async throws {
        await recorder.append(.clearAuthentication)
        if shouldFail {
            throw AuthenticationError.temporarilyUnavailable
        }
    }

    // MARK: Private

    private let recorder: SignOutCallRecorder
    private let shouldFail: Bool

}

// MARK: - SignOutLoginSessionRepository

private actor SignOutLoginSessionRepository: LoginSessionRepository {

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
        throw LoginSessionError.temporarilyUnavailable
    }

    func restore() async throws -> AuthenticatedUser? {
        nil
    }

    func signOut() async throws {
        await recorder.append(.signOut)
        if shouldFail {
            throw LoginSessionError.temporarilyUnavailable
        }
    }

    // MARK: Private

    private let recorder: SignOutCallRecorder
    private let shouldFail: Bool

}
