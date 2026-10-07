public protocol RegisterCurrentDeviceUseCase: Sendable {
    func callAsFunction() async throws
}
