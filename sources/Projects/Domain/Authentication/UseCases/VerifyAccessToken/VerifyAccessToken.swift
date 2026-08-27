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
