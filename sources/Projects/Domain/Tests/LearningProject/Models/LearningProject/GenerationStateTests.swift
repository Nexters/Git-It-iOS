import Foundation
import Testing

@testable import DomainLearningProject

@Suite("GenerationState")
struct GenerationStateTests {

    // MARK: Internal

    @Test
    func `같은 정규화 URL의 진행 중 기록은 하나만 시작할 수 있다`() {
        let started = GenerationState().beginning(githubRepoURL: Self.url, requestedAt: Self.requestedAt)
        #expect(started != nil)
        #expect(started?.records.count == 1)
        #expect(started?.beginning(githubRepoURL: "https://GitHub.com/Owner/Repo/", requestedAt: Self.requestedAt) == nil)
    }

    @Test
    func `종료한 기록이 남아 있어도 같은 URL로 다시 시작할 수 있다`() {
        let finished = GenerationState()
            .beginning(githubRepoURL: Self.url, requestedAt: Self.requestedAt)?
            .attachingProjectID("p1", toGithubRepoURL: Self.url)
            .finishing(projectID: "p1", status: .completed, at: Self.finishedAt)
        let restarted = finished?.beginning(githubRepoURL: Self.url, requestedAt: Self.finishedAt)
        #expect(restarted?.records.count == 1)
        #expect(restarted?.isCreating(githubRepoURL: Self.url) == true)
    }

    @Test
    func `진행 중 여부를 정규화한 URL로 판정한다`() {
        let state = GenerationState().beginning(githubRepoURL: Self.url, requestedAt: Self.requestedAt)
        #expect(state?.isCreating(githubRepoURL: "  https://GitHub.com/Owner/Repo/  ") == true)
        #expect(state?.isCreating(githubRepoURL: "https://github.com/owner/other") == false)
    }

    @Test
    func `진행 중이고 식별자가 부여된 기록만 활성 프로젝트로 센다`() {
        let state = GenerationState()
            .beginning(githubRepoURL: Self.url, requestedAt: Self.requestedAt)?
            .beginning(githubRepoURL: Self.otherURL, requestedAt: Self.requestedAt)?
            .attachingProjectID("p1", toGithubRepoURL: Self.url)
        #expect(state?.activeProjectIDs == ["p1"])

        let completed = state?.finishing(projectID: "p1", status: .completed, at: Self.finishedAt)
        #expect(completed?.activeProjectIDs.isEmpty == true)
    }

    @Test
    func `같은 프로젝트 식별자를 가진 기록은 하나만 남는다`() {
        let state = GenerationState()
            .beginning(githubRepoURL: Self.url, requestedAt: Self.requestedAt)?
            .beginning(githubRepoURL: Self.otherURL, requestedAt: Self.requestedAt)?
            .attachingProjectID("p1", toGithubRepoURL: Self.url)
            .attachingProjectID("p1", toGithubRepoURL: Self.otherURL)
        #expect(state?.records.count(where: { $0.projectID == "p1" }) == 1)
        #expect(state?.record(projectID: "p1")?.githubRepoURL == Self.otherURL)
    }

    @Test
    func `종료한 기록도 프로젝트 식별자로 조회할 수 있다`() {
        let state = GenerationState()
            .beginning(githubRepoURL: Self.url, requestedAt: Self.requestedAt)?
            .attachingProjectID("p1", toGithubRepoURL: Self.url)
            .finishing(projectID: "p1", status: .failed, at: Self.finishedAt)
        #expect(state?.record(projectID: "p1")?.status == .failed)
    }

    @Test
    func `URL 또는 프로젝트 식별자로 기록을 제거한다`() {
        let state = GenerationState()
            .beginning(githubRepoURL: Self.url, requestedAt: Self.requestedAt)?
            .attachingProjectID("p1", toGithubRepoURL: Self.url)
        #expect(state?.removing(githubRepoURL: "https://GitHub.com/Owner/Repo/").records.isEmpty == true)
        #expect(state?.removing(projectID: "p1").records.isEmpty == true)
    }

    @Test
    func `만료한 기록을 스냅샷에서 제외한다`() {
        let state = GenerationState()
            .beginning(githubRepoURL: Self.url, requestedAt: Self.requestedAt)?
            .beginning(githubRepoURL: Self.otherURL, requestedAt: Self.finishedAt)
        let purged = state?.purgingExpired(now: Self.finishedAt.addingTimeInterval(500), retentionLimit: 1_000)
        #expect(purged?.records.count == 1)
        #expect(purged?.records.first?.githubRepoURL == Self.otherURL)
    }

    // MARK: Private

    private static let url = "https://github.com/owner/repo"
    private static let otherURL = "https://github.com/owner/other"
    private static let requestedAt = Date(timeIntervalSince1970: 1_000)
    private static let finishedAt = Date(timeIntervalSince1970: 2_000)

}
