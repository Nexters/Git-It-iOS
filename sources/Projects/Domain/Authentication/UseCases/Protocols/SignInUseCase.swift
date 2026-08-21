public protocol SignInUseCase: Sendable {
    func callAsFunction(_ method: AuthenticationMethod) async -> AuthenticationOutcome
}
