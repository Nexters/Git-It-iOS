import DomainUseCaseInterface

public protocol GenerationOutcomeRepository: Sendable {
    func outcomes() async -> AsyncStream<GenerationOutcome>
    func deliveredOutcomes() async -> [GenerationOutcome]
}
