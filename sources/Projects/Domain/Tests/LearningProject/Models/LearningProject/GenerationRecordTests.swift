import Foundation
import Testing

@testable import DomainLearningProject

@Suite("GenerationRecord")
struct GenerationRecordTests {

    // MARK: Internal

    @Test
    func `저장소 URL의 공백과 대소문자와 후행 슬래시를 제거해 정규화한다`() {
        #expect(GenerationRecord.normalizedURL("  https://GitHub.com/Owner/Repo//  ") == "https://github.com/owner/repo")
        #expect(GenerationRecord.normalizedURL("https://github.com/owner/repo") == "https://github.com/owner/repo")
    }

    @Test
    func `생성한 기록은 정규화한 URL을 보유하고 진행 중 상태로 시작한다`() {
        let record = GenerationRecord(githubRepoURL: "https://GitHub.com/Owner/Repo/", requestedAt: Self.requestedAt)
        #expect(record.githubRepoURL == "https://github.com/owner/repo")
        #expect(record.projectID == nil)
        #expect(record.status == .inProgress)
        #expect(record.finishedAt == nil)
    }

    @Test
    func `진행 중 기록만 완료 또는 실패로 전이한다`() {
        let record = GenerationRecord(githubRepoURL: Self.url, requestedAt: Self.requestedAt)
        let completed = record.finishing(status: .completed, at: Self.finishedAt)
        #expect(completed.status == .completed)
        #expect(completed.finishedAt == Self.finishedAt)

        let reFinished = completed.finishing(status: .failed, at: Self.finishedAt.addingTimeInterval(10))
        #expect(reFinished == completed)
    }

    @Test
    func `진행 중으로 되돌리는 전이는 무시한다`() {
        let record = GenerationRecord(githubRepoURL: Self.url, requestedAt: Self.requestedAt)
        #expect(record.finishing(status: .inProgress, at: Self.finishedAt) == record)
    }

    @Test
    func `프로젝트 식별자를 연결해도 요청 시각과 상태는 유지한다`() {
        let record = GenerationRecord(githubRepoURL: Self.url, requestedAt: Self.requestedAt)
        let attached = record.attachingProjectID("p1")
        #expect(attached.projectID == "p1")
        #expect(attached.requestedAt == Self.requestedAt)
        #expect(attached.status == .inProgress)
    }

    @Test
    func `진행 중 기록은 요청 시각을 기준으로 만료를 판정한다`() {
        let record = GenerationRecord(githubRepoURL: Self.url, requestedAt: Self.requestedAt)
        #expect(!record.isExpired(now: Self.requestedAt.addingTimeInterval(3_600), retentionLimit: 3_600))
        #expect(record.isExpired(now: Self.requestedAt.addingTimeInterval(3_601), retentionLimit: 3_600))
    }

    @Test
    func `종료한 기록은 종료 시각을 기준으로 만료를 판정한다`() {
        let record = GenerationRecord(githubRepoURL: Self.url, requestedAt: Self.requestedAt)
            .finishing(status: .completed, at: Self.finishedAt)
        #expect(!record.isExpired(now: Self.finishedAt.addingTimeInterval(3_600), retentionLimit: 3_600))
        #expect(record.isExpired(now: Self.finishedAt.addingTimeInterval(3_601), retentionLimit: 3_600))
    }

    // MARK: Private

    private static let url = "https://github.com/owner/repo"
    private static let requestedAt = Date(timeIntervalSince1970: 1_000)
    private static let finishedAt = Date(timeIntervalSince1970: 2_000)

}
