public protocol VerifyAuthorizationUseCase: Sendable {
    func callAsFunction() async -> AuthorizationStatus
}
