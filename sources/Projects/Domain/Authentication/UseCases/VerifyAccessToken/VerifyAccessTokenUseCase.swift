public protocol VerifyAccessTokenUseCase: Sendable {
    func callAsFunction() async throws
}
