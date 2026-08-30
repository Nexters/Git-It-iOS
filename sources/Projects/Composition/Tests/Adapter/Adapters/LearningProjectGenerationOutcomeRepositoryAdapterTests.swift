import Foundation
import Testing
@testable import CompositionAdapter
@testable import DataLearningProject
@testable import DomainLearningProject

// MARK: - LearningProjectGenerationOutcomeRepositoryAdapterTests

@Suite("LearningProjectGenerationOutcomeRepositoryAdapter")
struct LearningProjectGenerationOutcomeRepositoryAdapterTests {

    @Test
    func `Data DTO를 Domain 모델로 변환해 순서대로 전달한다`() async {
        let remote = StubProjectGenerationOutcomeRemote(dtos: [
            ProjectGenerationOutcomeDTO(projectID: "project-1", status: .completed),
            ProjectGenerationOutcomeDTO(projectID: "project-2", status: .failed),
        ])
        let adapter = LearningProjectGenerationOutcomeRepositoryAdapter(remote: remote)

        var received = [LearningProjectGenerationOutcome]()
        for await outcome in await adapter.outcomes() {
            received.append(outcome)
        }

        #expect(received == [
            LearningProjectGenerationOutcome(projectID: "project-1", status: .completed),
            LearningProjectGenerationOutcome(projectID: "project-2", status: .failed),
        ])
    }

}

// MARK: - StubProjectGenerationOutcomeRemote

private struct StubProjectGenerationOutcomeRemote: ProjectGenerationOutcomeRemote {

    let dtos: [ProjectGenerationOutcomeDTO]

    func outcomes() -> AsyncStream<ProjectGenerationOutcomeDTO> {
        AsyncStream { continuation in
            for dto in dtos {
                continuation.yield(dto)
            }
            continuation.finish()
        }
    }

}
