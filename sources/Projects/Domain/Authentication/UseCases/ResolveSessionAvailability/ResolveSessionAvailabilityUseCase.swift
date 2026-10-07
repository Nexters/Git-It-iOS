public protocol ResolveSessionAvailabilityUseCase: Sendable {
    func callAsFunction() async -> SessionAvailability
}
