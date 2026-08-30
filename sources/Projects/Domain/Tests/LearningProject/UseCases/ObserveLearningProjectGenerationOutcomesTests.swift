import Testing

@testable import DomainLearningProject

// MARK: - ObserveLearningProjectGenerationOutcomesTests

@Suite("ObserveLearningProjectGenerationOutcomes")
struct ObserveLearningProjectGenerationOutcomesTests {
    @Test
    func `repository의 outcomes 스트림을 그대로 위임한다`() async {
        let outcomes = [
            LearningProjectGenerationOutcome(projectID: "project-1", status: .completed),
            LearningProjectGenerationOutcome(projectID: "project-2", status: .failed),
        ]
        let repository = ScriptedLearningProjectGenerationOutcomeRepository(scriptedOutcomes: outcomes)
        let observeLearningProjectGenerationOutcomes = ObserveLearningProjectGenerationOutcomes(
            repository: repository,
        )

        var received = [LearningProjectGenerationOutcome]()
        for await outcome in await observeLearningProjectGenerationOutcomes() {
            received.append(outcome)
        }

        #expect(received == outcomes)
    }
}

// MARK: - ScriptedLearningProjectGenerationOutcomeRepository

private struct ScriptedLearningProjectGenerationOutcomeRepository: LearningProjectGenerationOutcomeRepository {

    let scriptedOutcomes: [LearningProjectGenerationOutcome]

    func outcomes() async -> AsyncStream<LearningProjectGenerationOutcome> {
        let scriptedOutcomes = scriptedOutcomes
        return AsyncStream { continuation in
            for outcome in scriptedOutcomes {
                continuation.yield(outcome)
            }
            continuation.finish()
        }
    }

}
