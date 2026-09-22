import Foundation
import Testing

@testable import DomainProjectGeneration

@Suite("GenerationState")
struct GenerationStateTests {

    // MARK: Internal

    @Test
    func `같은 정규화 URL의 진행 중 기록은 하나만 시작할 수 있다`() {
        let started = GenerationState().beginning(
            repositoryURL: Self.url,
            requestedAt: Self.requestedAt,
        )
        #expect(started != nil)
        #expect(started?.records.count == 1)
        #expect(started?.beginning(
            repositoryURL: "https://GitHub.com/Owner/Repo/",
            requestedAt: Self.requestedAt,
        ) == nil)
    }

    @Test
    func `종료한 기록이 남아 있어도 같은 URL로 다시 시작할 수 있다`() {
        let finished = GenerationState()
            .beginning(
                repositoryURL: Self.url,
                requestedAt: Self.requestedAt,
            )?
            .attachingProjectID(
                "p1",
                toRepositoryURL: Self.url,
            )
            .finishing(
                projectID: "p1",
                status: .completed,
                at: Self.finishedAt,
            )
        let restarted = finished?.beginning(
            repositoryURL: Self.url,
            requestedAt: Self.finishedAt,
        )
        #expect(restarted?.records.count == 1)
        #expect(restarted?.isCreating(repositoryURL: Self.url) == true)
    }

    @Test
    func `진행 중 여부를 정규화한 URL로 판정한다`() {
        let state = GenerationState().beginning(
            repositoryURL: Self.url,
            requestedAt: Self.requestedAt,
        )
        #expect(state?.isCreating(repositoryURL: "  https://GitHub.com/Owner/Repo/  ") == true)
        #expect(state?.isCreating(repositoryURL: "https://github.com/owner/other") == false)
    }

    @Test
    func `진행 중이고 식별자가 부여된 기록만 활성 프로젝트로 센다`() {
        let state = GenerationState()
            .beginning(
                repositoryURL: Self.url,
                requestedAt: Self.requestedAt,
            )?
            .beginning(
                repositoryURL: Self.otherURL,
                requestedAt: Self.requestedAt,
            )?
            .attachingProjectID(
                "p1",
                toRepositoryURL: Self.url,
            )
        #expect(state?.activeProjectIDs == ["p1"])

        let completed = state?.finishing(
            projectID: "p1",
            status: .completed,
            at: Self.finishedAt,
        )
        #expect(completed?.activeProjectIDs.isEmpty == true)
    }

    @Test
    func `같은 프로젝트 식별자를 가진 기록은 하나만 남는다`() {
        let state = GenerationState()
            .beginning(
                repositoryURL: Self.url,
                requestedAt: Self.requestedAt,
            )?
            .beginning(
                repositoryURL: Self.otherURL,
                requestedAt: Self.requestedAt,
            )?
            .attachingProjectID(
                "p1",
                toRepositoryURL: Self.url,
            )
            .attachingProjectID(
                "p1",
                toRepositoryURL: Self.otherURL,
            )
        #expect(state?.records.count(where: { $0.projectID == "p1" }) == 1)
        #expect(state?.record(projectID: "p1")?.repositoryURL == Self.otherURL)
    }

    @Test
    func `종료한 기록도 프로젝트 식별자로 조회할 수 있다`() {
        let state = GenerationState()
            .beginning(
                repositoryURL: Self.url,
                requestedAt: Self.requestedAt,
            )?
            .attachingProjectID(
                "p1",
                toRepositoryURL: Self.url,
            )
            .finishing(
                projectID: "p1",
                status: .failed,
                at: Self.finishedAt,
            )
        #expect(state?.record(projectID: "p1")?.status == .failed)
    }

    @Test
    func `URL 또는 프로젝트 식별자로 기록을 제거한다`() {
        let state = GenerationState()
            .beginning(
                repositoryURL: Self.url,
                requestedAt: Self.requestedAt,
            )?
            .attachingProjectID(
                "p1",
                toRepositoryURL: Self.url,
            )
        #expect(state?.removing(repositoryURL: "https://GitHub.com/Owner/Repo/").records.isEmpty == true)
        #expect(state?.removing(projectID: "p1").records.isEmpty == true)
    }

    @Test
    func `만료한 기록을 스냅샷에서 제외한다`() {
        let state = GenerationState()
            .beginning(
                repositoryURL: Self.url,
                requestedAt: Self.requestedAt,
            )?
            .beginning(
                repositoryURL: Self.otherURL,
                requestedAt: Self.finishedAt,
            )
        let purged = state?.purgingExpired(
            now: Self.finishedAt.addingTimeInterval(500),
            retentionLimit: 1_000,
        )
        #expect(purged?.records.count == 1)
        #expect(purged?.records.first?.repositoryURL == Self.otherURL)
    }

    @Test
    func `저장소 URL의 공백과 대소문자와 후행 슬래시를 제거해 정규화한다`() {
        #expect(GenerationRecord.normalizedURL("  https://GitHub.com/Owner/Repo//  ") == "https://github.com/owner/repo")
        #expect(GenerationRecord.normalizedURL("https://github.com/owner/repo") == "https://github.com/owner/repo")
    }

    @Test
    func `생성한 기록은 정규화한 URL을 보유하고 진행 중 상태로 시작한다`() {
        let record = GenerationRecord(
            repositoryURL: "https://GitHub.com/Owner/Repo/",
            requestedAt: Self.requestedAt,
        )
        #expect(record.repositoryURL == "https://github.com/owner/repo")
        #expect(record.projectID == nil)
        #expect(record.status == .inProgress)
        #expect(record.finishedAt == nil)
    }

    @Test
    func `진행 중 기록만 완료 또는 실패로 전이한다`() {
        let record = GenerationRecord(
            repositoryURL: Self.url,
            requestedAt: Self.requestedAt,
        )
        let completed = record.finishing(
            status: .completed,
            at: Self.finishedAt,
        )
        #expect(completed.status == .completed)
        #expect(completed.finishedAt == Self.finishedAt)

        let reFinished = completed.finishing(
            status: .failed,
            at: Self.finishedAt.addingTimeInterval(10),
        )
        #expect(reFinished == completed)
    }

    @Test
    func `진행 중으로 되돌리는 전이는 무시한다`() {
        let record = GenerationRecord(
            repositoryURL: Self.url,
            requestedAt: Self.requestedAt,
        )
        #expect(record.finishing(
            status: .inProgress,
            at: Self.finishedAt,
        ) == record)
    }

    @Test
    func `프로젝트 식별자를 연결해도 요청 시각과 상태는 유지한다`() {
        let record = GenerationRecord(
            repositoryURL: Self.url,
            requestedAt: Self.requestedAt,
        )
        let attached = record.attachingProjectID("p1")
        #expect(attached.projectID == "p1")
        #expect(attached.requestedAt == Self.requestedAt)
        #expect(attached.status == .inProgress)
    }

    @Test
    func `진행 중 기록은 요청 시각을 기준으로 만료를 판정한다`() {
        let record = GenerationRecord(
            repositoryURL: Self.url,
            requestedAt: Self.requestedAt,
        )
        #expect(!record.isExpired(
            now: Self.requestedAt.addingTimeInterval(3_600),
            retentionLimit: 3_600,
        ))
        #expect(record.isExpired(
            now: Self.requestedAt.addingTimeInterval(3_601),
            retentionLimit: 3_600,
        ))
    }

    @Test
    func `종료한 기록은 종료 시각을 기준으로 만료를 판정한다`() {
        let record = GenerationRecord(
            repositoryURL: Self.url,
            requestedAt: Self.requestedAt,
        )
        .finishing(
            status: .completed,
            at: Self.finishedAt,
        )
        #expect(!record.isExpired(
            now: Self.finishedAt.addingTimeInterval(3_600),
            retentionLimit: 3_600,
        ))
        #expect(record.isExpired(
            now: Self.finishedAt.addingTimeInterval(3_601),
            retentionLimit: 3_600,
        ))
    }

    @Test
    func `준비 완료 시각은 요청 시각에 최소 대기 시간을 더한 값이다`() {
        let record = GenerationRecord(
            repositoryURL: Self.url,
            requestedAt: Self.requestedAt,
        )
        #expect(GenerationWaitPolicy.standard.readyDate(for: record) == Self.requestedAt.addingTimeInterval(300))
        #expect(GenerationWaitPolicy.standard.retentionLimit == 3_600)
    }

    // MARK: Private

    private static let url = "https://github.com/owner/repo"
    private static let otherURL = "https://github.com/owner/other"
    private static let requestedAt = Date(timeIntervalSince1970: 1_000)
    private static let finishedAt = Date(timeIntervalSince1970: 2_000)

}
