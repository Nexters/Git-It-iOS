import Testing

@testable import DomainAuthentication

// MARK: - SignInTests

@Suite("SignIn")
struct SignInTests {
    @Test
    func `선택한 인증 방식으로 인증한 뒤 grant로 세션을 시작하고 needsCuration을 전달한다`() async {
        let recorder = SignInCallRecorder()
        let grant = AuthenticationGrant(
            id: .init(rawValue: "grant-1"),
            method: .apple,
        )
        let user = AuthenticatedUser(
            id: "user-1",
            availability: .available,
            displayName: nil,
        )
        let authenticationRepository = SignInAuthenticationRepository(
            behavior: .succeed(grant),
            recorder: recorder,
        )
        let loginSessionRepository = SignInLoginSessionRepository(
            behavior: .succeed(user),
            recorder: recorder,
            needsCuration: true,
        )
        let signIn = SignIn(
            authenticationRepository: authenticationRepository,
            loginSessionRepository: loginSessionRepository,
        )

        let result = await signIn(.apple)

        #expect(result == .success(user, needsCuration: true))
        #expect(await recorder.snapshot() == [.authenticate(.apple), .start(grant), .currentSession])
    }

    @Test
    func `needsCuration이 false면 그대로 전달한다`() async {
        let recorder = SignInCallRecorder()
        let grant = AuthenticationGrant(
            id: .init(rawValue: "grant-1"),
            method: .apple,
        )
        let user = AuthenticatedUser(
            id: "user-1",
            availability: .available,
            displayName: nil,
        )
        let authenticationRepository = SignInAuthenticationRepository(
            behavior: .succeed(grant),
            recorder: recorder,
        )
        let loginSessionRepository = SignInLoginSessionRepository(
            behavior: .succeed(user),
            recorder: recorder,
            needsCuration: false,
        )
        let signIn = SignIn(
            authenticationRepository: authenticationRepository,
            loginSessionRepository: loginSessionRepository,
        )

        let result = await signIn(.apple)

        #expect(result == .success(user, needsCuration: false))
    }

    @Test
    func `인증 일시 실패 시 세션을 시작하지 않고 retryableFailure를 반환한다`() async {
        let recorder = SignInCallRecorder()
        let authenticationRepository = SignInAuthenticationRepository(
            behavior: .fail,
            recorder: recorder,
        )
        let loginSessionRepository = SignInLoginSessionRepository(
            behavior: .fail,
            recorder: recorder,
            needsCuration: false,
        )
        let signIn = SignIn(
            authenticationRepository: authenticationRepository,
            loginSessionRepository: loginSessionRepository,
        )

        let result = await signIn(.apple)

        #expect(result == .retryableFailure)
        #expect(await recorder.snapshot() == [.authenticate(.apple)])
    }

    @Test
    func `사용자 취소 시 cancelled를 retryableFailure와 구분해 반환한다`() async {
        let recorder = SignInCallRecorder()
        let authenticationRepository = SignInAuthenticationRepository(
            behavior: .cancel,
            recorder: recorder,
        )
        let loginSessionRepository = SignInLoginSessionRepository(
            behavior: .fail,
            recorder: recorder,
            needsCuration: false,
        )
        let signIn = SignIn(
            authenticationRepository: authenticationRepository,
            loginSessionRepository: loginSessionRepository,
        )

        let result = await signIn(.apple)

        #expect(result == .cancelled)
        #expect(result != .retryableFailure)
        #expect(await recorder.snapshot() == [.authenticate(.apple)])
    }

    @Test
    func `세션 시작 실패 시 인증 참조를 정리하고 retryableFailure를 반환한다`() async {
        let recorder = SignInCallRecorder()
        let grant = AuthenticationGrant(
            id: .init(rawValue: "grant-1"),
            method: .apple,
        )
        let authenticationRepository = SignInAuthenticationRepository(
            behavior: .succeed(grant),
            recorder: recorder,
        )
        let loginSessionRepository = SignInLoginSessionRepository(
            behavior: .fail,
            recorder: recorder,
            needsCuration: false,
        )
        let signIn = SignIn(
            authenticationRepository: authenticationRepository,
            loginSessionRepository: loginSessionRepository,
        )

        let result = await signIn(.apple)

        #expect(result == .retryableFailure)
        #expect(
            await recorder.snapshot() == [
                .authenticate(.apple),
                .start(grant),
                .clearAuthentication,
            ]
        )
    }
}

// MARK: - SignInCallRecorder

private actor SignInCallRecorder {

    // MARK: Internal

    enum Call: Equatable, Sendable {
        case authenticate(AuthenticationMethod)
        case start(AuthenticationGrant)
        case currentSession
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

// MARK: - SignInAuthenticationRepository

private actor SignInAuthenticationRepository: AuthenticationRepository {

    // MARK: Lifecycle

    init(
        behavior: Behavior,
        recorder: SignInCallRecorder,
    ) {
        self.behavior = behavior
        self.recorder = recorder
    }

    // MARK: Internal

    enum Behavior: Sendable {
        case succeed(AuthenticationGrant)
        case cancel
        case fail
    }

    func authenticate(using method: AuthenticationMethod) async throws -> AuthenticationGrant {
        await recorder.append(.authenticate(method))

        switch behavior {
        case .succeed(let grant):
            return grant

        case .cancel:
            throw AuthenticationError.cancelled

        case .fail:
            throw AuthenticationError.temporarilyUnavailable
        }
    }

    func authorizationStatus() async throws -> AuthorizationStatus {
        .authorized
    }

    func authorizationChanges() async -> AsyncStream<AuthorizationStatus> {
        AsyncStream { $0.finish() }
    }

    func clearAuthentication() async throws {
        await recorder.append(.clearAuthentication)
    }

    // MARK: Private

    private let behavior: Behavior
    private let recorder: SignInCallRecorder

}

// MARK: - SignInLoginSessionRepository

private actor SignInLoginSessionRepository: LoginSessionRepository {

    // MARK: Lifecycle

    init(
        behavior: Behavior,
        recorder: SignInCallRecorder,
        needsCuration: Bool,
    ) {
        self.behavior = behavior
        self.recorder = recorder
        self.needsCuration = needsCuration
    }

    // MARK: Internal

    enum Behavior: Sendable {
        case succeed(AuthenticatedUser)
        case fail
    }

    func start(with grant: AuthenticationGrant) async throws -> AuthenticatedUser {
        await recorder.append(.start(grant))

        switch behavior {
        case .succeed(let user):
            return user

        case .fail:
            throw LoginSessionError.temporarilyUnavailable
        }
    }

    func restore() async throws -> AuthenticatedUser? {
        nil
    }

    func signOut() async throws { }

    func currentSession() async -> SessionRecord? {
        await recorder.append(.currentSession)
        return SessionRecord(
            tokens: SessionTokens(
                accessToken: "access-token",
                refreshToken: "refresh-token",
                accessTokenExpiresAt: nil,
                refreshTokenExpiresAt: nil,
            ),
            onboarding: LocalOnboardingState(
                needsCuration: needsCuration,
                acceptedLegalVersions: [],
                acceptedAt: nil,
            ),
        )
    }

    func replaceTokens(_: SessionTokens) async throws { }
    func updateOnboarding(_: LocalOnboardingState) async throws { }
    func refresh() async throws -> SessionTokens {
        throw LoginSessionError.temporarilyUnavailable
    }

    func verifyAccessToken() async throws { }

    // MARK: Private

    private let behavior: Behavior
    private let recorder: SignInCallRecorder
    private let needsCuration: Bool

}
