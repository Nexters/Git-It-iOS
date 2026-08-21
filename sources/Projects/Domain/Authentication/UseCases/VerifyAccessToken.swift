/// UC13 — Access token 유효성 확인. local onboarding state는 변경하지 않으며 401/temporary
/// failure를 그대로 전파해 Root refresh/session flow가 처리하도록 한다.
public struct VerifyAccessToken: VerifyAccessTokenUseCase {

    // MARK: Lifecycle

    public init(loginSessionRepository: any LoginSessionRepository) {
        self.loginSessionRepository = loginSessionRepository
    }

    // MARK: Public

    public func callAsFunction() async throws {
        try await loginSessionRepository.verifyAccessToken()
    }

    // MARK: Private

    private let loginSessionRepository: any LoginSessionRepository

}
