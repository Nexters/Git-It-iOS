import Foundation

@testable import DomainLearningProject

// MARK: - StubGenerationProgressRepository

actor StubGenerationProgressRepository: GenerationProgressRepository {

    // MARK: Internal

    enum Call: Equatable, Sendable {
        case load
        case save(GenerationProgress)
        case clear
    }

    private(set) var calls = [Call]()

    func load() async -> GenerationProgress? {
        calls.append(.load)
        return stored
    }

    func save(_ progress: GenerationProgress) async {
        calls.append(.save(progress))
        stored = progress
    }

    func clear() async {
        calls.append(.clear)
        stored = nil
    }

    // MARK: Private

    private var stored: GenerationProgress?

}
