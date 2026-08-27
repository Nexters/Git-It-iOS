public protocol RefreshSessionUseCase: Sendable {
    func callAsFunction() async -> SessionRefreshOutcome
}
