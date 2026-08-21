public protocol LoginSessionRepository: Sendable {
    func start(with grant: AuthenticationGrant) async throws -> AuthenticatedUser
    func restore() async throws -> AuthenticatedUser?
    func signOut() async throws

    /// 로컬 세션 정본(token pair, onboarding state)을 조회한다. 세션이 없으면 nil.
    func currentSession() async -> SessionRecord?

    /// 새 token pair를 원자적으로 교체한다. 기존 onboarding 값은 보존한다.
    func replaceTokens(_ tokens: SessionTokens) async throws

    /// `needsCuration`을 포함한 onboarding 상태를 원자적으로 갱신한다.
    func updateOnboarding(_ onboarding: LocalOnboardingState) async throws

    /// refresh token으로 새 token pair를 발급받는다. 서버 capability가 없으면
    /// `LoginSessionError.temporarilyUnavailable`을 던진다(임의 성공 금지).
    func refresh() async throws -> SessionTokens

    /// 현재 access token의 서버 유효성을 확인한다. 401이면 `LoginSessionError.unauthorized`,
    /// 5xx/transport면 `LoginSessionError.temporarilyUnavailable`을 던진다.
    func verifyAccessToken() async throws
}
