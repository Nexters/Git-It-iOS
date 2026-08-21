public protocol SignOutUseCase: Sendable {
    func callAsFunction() async -> AuthenticationOutcome
}
