import Foundation
import Testing
@testable import CompositionLearningProject
@testable import DataLearningProject
@testable import DomainProjectGeneration

// MARK: - GenerationOutcomeRepositoryAdapterTests

@Suite("GenerationOutcomeRepositoryAdapter")
struct GenerationOutcomeRepositoryAdapterTests {

    // MARK: Internal

    @Test
    func `Data DTO를 Domain 모델로 변환해 순서대로 전달한다`() async {
        let adapter = GenerationOutcomeRepositoryAdapter(source: StubOutcomeSource(dtos: [
            QuizGenerationOutcomeDTO(
                projectID: "project-1",
                status: .completed,
            ),
            QuizGenerationOutcomeDTO(
                projectID: "project-2",
                status: .failed,
            ),
        ]))

        var received = [GenerationOutcome]()
        for await outcome in await adapter.outcomes() {
            received.append(outcome)
        }

        #expect(received == [
            GenerationOutcome(
                projectID: "project-1",
                status: .completed,
            ),
            GenerationOutcome(
                projectID: "project-2",
                status: .failed,
            ),
        ])
    }

    // MARK: Private

    private struct StubOutcomeSource: QuizGenerationOutcomeSource {

        let dtos: [QuizGenerationOutcomeDTO]

        func outcomes() -> AsyncStream<QuizGenerationOutcomeDTO> {
            AsyncStream { continuation in
                for dto in dtos {
                    continuation.yield(dto)
                }
                continuation.finish()
            }
        }

    }

}
