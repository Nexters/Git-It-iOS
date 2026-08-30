import Testing

@testable import DomainAuthentication

// MARK: - RefreshSessionTests

@Suite("RefreshSession")
struct RefreshSessionTests {
    @Test
    func `성공하면 새 token pair로 원자적으로 교체한다`() async {
        let tokens = SessionTokens(
            accessToken: "new-access",
            refreshToken: "new-refresh",
            accessTokenExpiresAt: nil,
            refreshTokenExpiresAt: nil,
        )
        let repository = RefreshSessionRepository(behavior: .succeed(tokens))
        let refreshSession = RefreshSession(loginSessionRepository: repository)

        let outcome = await refreshSession()

        #expect(outcome == .refreshed(tokens))
        #expect(await repository.replacedTokens == tokens)
    }

    @Test
    func `거부되면 rejected를 반환하고 credential을 지우지 않는다`() async {
        let repository = RefreshSessionRepository(behavior: .fail(.refreshRejectedOrExpired))
        let refreshSession = RefreshSession(loginSessionRepository: repository)

        let outcome = await refreshSession()

        #expect(outcome == .rejected)
    }

    @Test
    func `일시적 실패면 temporarilyUnavailable을 반환한다`() async {
        let repository = RefreshSessionRepository(behavior: .fail(.temporarilyUnavailable))
        let refreshSession = RefreshSession(loginSessionRepository: repository)

        let outcome = await refreshSession()

        #expect(outcome == .temporarilyUnavailable)
    }

    @Test
    func `동시 호출은 하나의 실행에 합류한다`() async {
        let repository = RefreshSessionRepository(behavior: .succeedAfterDelay)
        let coordinator = SingleFlightCoordinator()
        let refreshSession = RefreshSession(loginSessionRepository: repository, coordinator: coordinator)

        async let first = refreshSession()
        async let second = refreshSession()
        _ = await (first, second)

        #expect(await repository.refreshCallCount == 1)
    }
}

// MARK: - RefreshSessionRepository

private actor RefreshSessionRepository: LoginSessionRepository {

    // MARK: Lifecycle

    init(behavior: Behavior) {
        self.behavior = behavior
    }

    // MARK: Internal

    enum Behavior: Sendable {
        case succeed(SessionTokens)
        case succeedAfterDelay
        case fail(LoginSessionError)
    }

    private(set) var replacedTokens: SessionTokens?
    private(set) var refreshCallCount = 0

    func start(with _: AuthenticationGrant) async throws -> AuthenticatedUser {
        throw LoginSessionError.temporarilyUnavailable
    }

    func restore() async throws -> AuthenticatedUser? {
        nil
    }

    func signOut() async throws { }

    func currentSession() async -> SessionRecord? {
        nil
    }

    func replaceTokens(_ tokens: SessionTokens) async throws {
        replacedTokens = tokens
    }

    func updateOnboarding(_: LocalOnboardingState) async throws { }

    func refresh() async throws -> SessionTokens {
        refreshCallCount += 1
        switch behavior {
        case .succeed(let tokens):
            return tokens

        case .succeedAfterDelay:
            try? await Task.sleep(nanoseconds: 10_000_000)
            return SessionTokens(
                accessToken: "delayed-access",
                refreshToken: "delayed-refresh",
                accessTokenExpiresAt: nil,
                refreshTokenExpiresAt: nil,
            )

        case .fail(let error):
            throw error
        }
    }

    func verifyAccessToken() async throws { }

    // MARK: Private

    private let behavior: Behavior

}
