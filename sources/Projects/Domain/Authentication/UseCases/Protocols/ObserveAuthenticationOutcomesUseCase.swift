public protocol ObserveAuthenticationOutcomesUseCase: Sendable {
    func callAsFunction() async -> AsyncStream<AuthenticationOutcome>
}
