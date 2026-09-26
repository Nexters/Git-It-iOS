import Foundation
import Testing

@testable import DomainProjectGeneration

@Suite("GenerationWaitPolicy")
struct GenerationWaitPolicyTests {

    // MARK: Internal

    @Test
    func `진행 중 기록의 보관 기한은 요청 시각에 보관 기간을 더한 값이다`() {
        let record = GenerationRecord(
            repositoryURL: Self.url,
            requestedAt: Self.requestedAt,
        )

        #expect(GenerationWaitPolicy.standard.expiryDate(for: record) == Self.requestedAt.addingTimeInterval(3_600))
    }

    @Test
    func `종료한 기록의 보관 기한은 종료 시각에 보관 기간을 더한 값이다`() {
        let record = GenerationRecord(
            repositoryURL: Self.url,
            requestedAt: Self.requestedAt,
            status: .completed,
            finishedAt: Self.finishedAt,
        )

        #expect(GenerationWaitPolicy.standard.expiryDate(for: record) == Self.finishedAt.addingTimeInterval(3_600))
    }

    @Test
    func `결과 도착 후 300초까지는 알림이 유효하다`() {
        let record = GenerationRecord(
            repositoryURL: Self.url,
            requestedAt: Self.requestedAt,
            status: .completed,
            finishedAt: Self.finishedAt,
        )

        #expect(GenerationWaitPolicy.standard.isReminderValid(
            record,
            now: Self.finishedAt.addingTimeInterval(300),
        ))
    }

    @Test
    func `결과 도착 후 300초가 지나면 알림이 유효하지 않다`() {
        let record = GenerationRecord(
            repositoryURL: Self.url,
            requestedAt: Self.requestedAt,
            status: .completed,
            finishedAt: Self.finishedAt,
        )

        #expect(!GenerationWaitPolicy.standard.isReminderValid(
            record,
            now: Self.finishedAt.addingTimeInterval(301),
        ))
    }

    @Test
    func `결과가 도착하지 않은 기록의 알림은 유효하지 않다`() {
        let record = GenerationRecord(
            repositoryURL: Self.url,
            requestedAt: Self.requestedAt,
        )

        #expect(!GenerationWaitPolicy.standard.isReminderValid(
            record,
            now: Self.requestedAt,
        ))
    }

    // MARK: Private

    private static let url = "https://github.com/owner/repo"
    private static let requestedAt = Date(timeIntervalSince1970: 1_000)
    private static let finishedAt = Date(timeIntervalSince1970: 2_000)

}
