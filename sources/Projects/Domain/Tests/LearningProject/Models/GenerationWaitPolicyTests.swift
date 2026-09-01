import Foundation
import Testing

@testable import DomainLearningProject

@Suite("GenerationWaitPolicy")
struct GenerationWaitPolicyTests {
    @Test
    func `기본 정책은 최소 대기 300초와 보존 상한 3600초를 사용한다`() {
        let policy = GenerationWaitPolicy.standard

        #expect(policy.minimumWait == 300)
        #expect(policy.retentionLimit == 3600)
    }

    @Test
    func `대기 만료 시각은 요청 시각에 최소 대기 시간을 더한 값이다`() {
        let requestedAt = Date(timeIntervalSince1970: 1_000)
        let progress = GenerationProgress(projectID: "project-1", requestedAt: requestedAt)

        let readyDate = GenerationWaitPolicy.standard.readyDate(for: progress)

        #expect(readyDate == Date(timeIntervalSince1970: 1_300))
    }

    @Test
    func `보존 상한을 넘기지 않은 진행 상태는 만료로 판정하지 않는다`() {
        let requestedAt = Date(timeIntervalSince1970: 0)
        let progress = GenerationProgress(projectID: "project-1", requestedAt: requestedAt)

        let isExpired = GenerationWaitPolicy.standard.isExpired(
            progress,
            now: Date(timeIntervalSince1970: 3_600),
        )

        #expect(isExpired == false)
    }

    @Test
    func `보존 상한을 넘긴 진행 상태는 만료로 판정한다`() {
        let requestedAt = Date(timeIntervalSince1970: 0)
        let progress = GenerationProgress(projectID: "project-1", requestedAt: requestedAt)

        let isExpired = GenerationWaitPolicy.standard.isExpired(
            progress,
            now: Date(timeIntervalSince1970: 3_601),
        )

        #expect(isExpired)
    }

    @Test
    func `테스트는 짧은 값으로 정책을 대체할 수 있다`() {
        let policy = GenerationWaitPolicy(minimumWait: 1, retentionLimit: 2)
        let progress = GenerationProgress(
            projectID: "project-1",
            requestedAt: Date(timeIntervalSince1970: 0),
        )

        #expect(policy.readyDate(for: progress) == Date(timeIntervalSince1970: 1))
        #expect(policy.isExpired(progress, now: Date(timeIntervalSince1970: 3)))
    }
}
