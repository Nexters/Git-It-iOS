import Foundation
import Testing

@testable import DataLearningProject

// MARK: - QuizGenerationOutcomeDTOTests

@Suite("QuizGenerationOutcomeDTO 디코딩")
struct QuizGenerationOutcomeDTOTests {

    // MARK: Internal

    @Test
    func `completed 상태 payload를 디코딩한다`() {
        let dto = QuizGenerationOutcomeDTO(
            rawPayload: ["projectId": "project-1", "status": "completed"],
            deliveredAt: Self.deliveredAt,
        )

        #expect(dto == QuizGenerationOutcomeDTO(
            projectID: "project-1",
            status: .completed,
            deliveredAt: Self.deliveredAt,
        ))
    }

    @Test
    func `failed 상태 payload를 디코딩한다`() {
        let dto = QuizGenerationOutcomeDTO(
            rawPayload: ["projectId": "project-2", "status": "failed"],
            deliveredAt: Self.deliveredAt,
        )

        #expect(dto == QuizGenerationOutcomeDTO(
            projectID: "project-2",
            status: .failed,
            deliveredAt: Self.deliveredAt,
        ))
    }

    @Test
    func `알 수 없는 status 값은 디코딩에 실패한다`() {
        let dto = QuizGenerationOutcomeDTO(
            rawPayload: ["projectId": "project-1", "status": "pending"],
            deliveredAt: Self.deliveredAt,
        )

        #expect(dto == nil)
    }

    @Test
    func `projectId 키가 없으면 디코딩에 실패한다`() {
        let dto = QuizGenerationOutcomeDTO(
            rawPayload: ["status": "completed"],
            deliveredAt: Self.deliveredAt,
        )

        #expect(dto == nil)
    }

    @Test
    func `status 키가 없으면 디코딩에 실패한다`() {
        let dto = QuizGenerationOutcomeDTO(
            rawPayload: ["projectId": "project-1"],
            deliveredAt: Self.deliveredAt,
        )

        #expect(dto == nil)
    }

    @Test
    func `payload로 만든 결과는 전달 시각을 그대로 담는다`() {
        let dto = QuizGenerationOutcomeDTO(
            rawPayload: ["projectId": "project-1", "status": "completed"],
            deliveredAt: Self.deliveredAt,
        )

        #expect(dto?.deliveredAt == Self.deliveredAt)
    }

    // MARK: Private

    private static let deliveredAt = Date(timeIntervalSince1970: 1_000)

}
