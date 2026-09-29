import Foundation
import Testing

@testable import DomainProjectGeneration

@Suite("ProjectGenerationState")
struct ProjectGenerationStateTests {

    // MARK: Internal

    @Test
    func `진행 중 단계의 요청이 하나라도 있으면 생성 중이다`() {
        let state = ProjectGenerationState(requests: [
            Self.request(
                "https://github.com/owner/ready",
                .ready,
            ),
            Self.request(
                "https://github.com/owner/progress",
                .inProgress,
            ),
        ])

        #expect(state.hasRequestInProgress)
    }

    @Test(arguments: [
        [ProjectGenerationPhase.ready],
        [.failed],
        [.ready, .failed],
        [],
    ])
    func `진행 중 단계의 요청이 없으면 생성 중이 아니다`(phases: [ProjectGenerationPhase]) {
        let state = ProjectGenerationState(requests: phases.enumerated().map { index, phase in
            Self.request(
                "https://github.com/owner/repo\(index)",
                phase,
            )
        })

        #expect(!state.hasRequestInProgress)
    }

    @Test
    func `프로젝트 식별자가 연결되지 않은 진행 중 요청도 생성 중이다`() {
        let state = ProjectGenerationState(requests: [
            Self.request(
                "https://github.com/owner/repo",
                .inProgress,
                projectID: nil,
            )
        ])

        #expect(state.hasRequestInProgress)
    }

    // MARK: Private

    private static let requestedAt = Date(timeIntervalSince1970: 10_000)

    private static func request(
        _ repositoryURL: String,
        _ phase: ProjectGenerationPhase,
        projectID: String? = "p1",
    ) -> ProjectGenerationRequestState {
        ProjectGenerationRequestState(
            repositoryURL: repositoryURL,
            projectID: projectID,
            requestedAt: requestedAt,
            phase: phase,
        )
    }

}
