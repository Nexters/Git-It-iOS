import DomainUseCaseDependency
import Foundation
import Synchronization

@testable import DomainUseCaseInterface

final class StubGenerationOutcomeRepository: GenerationOutcomeRepository, Sendable {

    // MARK: Internal

    func outcomes() async -> AsyncStream<GenerationOutcome> {
        AsyncStream { continuation in
            let subscriptionID = UUID()
            continuations.withLock { $0[subscriptionID] = continuation }
            continuation.onTermination = { [weak self] _ in
                self?.continuations.withLock { _ = $0.removeValue(forKey: subscriptionID) }
            }
        }
    }

    func deliveredOutcomes() async -> [GenerationOutcome] {
        delivered.withLock { $0 }
    }

    func setDeliveredOutcomes(_ outcomes: [GenerationOutcome]) {
        delivered.withLock { $0 = outcomes }
    }

    func emit(_ outcome: GenerationOutcome) {
        let targets = continuations.withLock { Array($0.values) }
        for continuation in targets {
            continuation.yield(outcome)
        }
    }

    // MARK: Private

    private let continuations = Mutex([UUID: AsyncStream<GenerationOutcome>.Continuation]())
    private let delivered = Mutex([GenerationOutcome]())

}
