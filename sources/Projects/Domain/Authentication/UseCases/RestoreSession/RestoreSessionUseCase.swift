public protocol RestoreSessionUseCase: Sendable {
    func callAsFunction() async -> RestoreSessionResult
}
