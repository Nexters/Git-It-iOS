public protocol AuthenticationOutcomesUseCase: Sendable {
    func callAsFunction() async -> AsyncStream<AuthenticationOutcome>
}
