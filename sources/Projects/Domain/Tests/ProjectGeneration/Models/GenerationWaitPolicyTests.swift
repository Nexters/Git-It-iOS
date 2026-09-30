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

    // MARK: Private

    private static let url = "https://github.com/owner/repo"
    private static let requestedAt = Date(timeIntervalSince1970: 1_000)
    private static let finishedAt = Date(timeIntervalSince1970: 2_000)

}
