import Testing

@testable import DomainLearningProject

// MARK: - LearningProjectOutcomesTests

@Suite("LearningProjectOutcomes")
struct LearningProjectOutcomesTests {
    @Test
    func `repository의 outcomes 스트림을 그대로 위임한다`() async {
        let outcomes = [
            GenerationOutcome(projectID: "project-1", status: .completed),
            GenerationOutcome(projectID: "project-2", status: .failed),
        ]
        let repository = ScriptedGenerationOutcomeRepository(scriptedOutcomes: outcomes)
        let learningProjectOutcomes = LearningProjectOutcomes(
            repository: repository
        )

        var received = [GenerationOutcome]()
        for await outcome in await learningProjectOutcomes() {
            received.append(outcome)
        }

        #expect(received == outcomes)
    }
}

// MARK: - ScriptedGenerationOutcomeRepository

private struct ScriptedGenerationOutcomeRepository: GenerationOutcomeRepository {

    let scriptedOutcomes: [GenerationOutcome]

    func outcomes() async -> AsyncStream<GenerationOutcome> {
        let scriptedOutcomes = scriptedOutcomes
        return AsyncStream { continuation in
            for outcome in scriptedOutcomes {
                continuation.yield(outcome)
            }
            continuation.finish()
        }
    }

}
