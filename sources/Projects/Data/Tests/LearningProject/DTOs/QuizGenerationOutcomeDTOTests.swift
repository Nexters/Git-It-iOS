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

    @Test
    func `서버 QUIZ_READY 알림 원문을 완료 결과로 인식한다`() {
        let dto = QuizGenerationOutcomeDTO(
            rawPayload: Self.serverPayload(
                projectID: "6abbb1b4f55054fd8fbb4ca3",
                type: "QUIZ_READY",
                alertTitle: "프로젝트 준비 완료",
                alertBody: "새 문제가 도착했어요",
            ),
            deliveredAt: Self.deliveredAt,
        )

        #expect(dto == QuizGenerationOutcomeDTO(
            projectID: "6abbb1b4f55054fd8fbb4ca3",
            status: .completed,
            deliveredAt: Self.deliveredAt,
        ))
    }

    @Test(arguments: ["6abbacabf55054fd8fbb479d", "6abbaf3ef55054fd8fbb4a78"])
    func `서버 QUIZ_REJECTED 알림 원문을 실패 결과로 인식한다`(projectID: String) {
        let dto = QuizGenerationOutcomeDTO(
            rawPayload: Self.serverPayload(
                projectID: projectID,
                type: "QUIZ_REJECTED",
                alertTitle: "문제를 만들 수 없는 저장소예요",
                alertBody: "다른 저장소로 등록해 주세요",
            ),
            deliveredAt: Self.deliveredAt,
        )

        #expect(dto == QuizGenerationOutcomeDTO(
            projectID: projectID,
            status: .failed,
            deliveredAt: Self.deliveredAt,
        ))
    }

    @Test
    func `type과 status가 함께 있으면 type을 따른다`() {
        let dto = QuizGenerationOutcomeDTO(
            rawPayload: ["projectId": "p", "type": "QUIZ_REJECTED", "status": "completed"],
            deliveredAt: Self.deliveredAt,
        )

        #expect(dto?.status == .failed)
    }

    @Test
    func `알 수 없는 type이면 status로 판정한다`() {
        let dto = QuizGenerationOutcomeDTO(
            rawPayload: ["projectId": "p", "type": "QUIZ_UNKNOWN", "status": "completed"],
            deliveredAt: Self.deliveredAt,
        )

        #expect(dto?.status == .completed)
    }

    @Test(arguments: ["quiz_ready", "QUIZ_FAILED"])
    func `type 값은 대소문자와 표기가 정확히 같아야 인식한다`(type: String) {
        let dto = QuizGenerationOutcomeDTO(
            rawPayload: ["projectId": "p", "type": type],
            deliveredAt: Self.deliveredAt,
        )

        #expect(dto == nil)
    }

    @Test
    func `projectId가 빈 문자열이면 인식하지 않는다`() {
        let dto = QuizGenerationOutcomeDTO(
            rawPayload: ["projectId": "", "type": "QUIZ_READY"],
            deliveredAt: Self.deliveredAt,
        )

        #expect(dto == nil)
    }

    // MARK: Private

    private static let deliveredAt = Date(timeIntervalSince1970: 1_000)

    private static func serverPayload(
        projectID: String,
        type: String,
        alertTitle: String,
        alertBody: String,
    ) -> [String: String] {
        [
            "projectId": projectID,
            "type": type,
            "aps": "{\n    alert = {\n        body = \"\(alertBody)\";\n        title = \"\(alertTitle)\";\n    };\n}",
            "gcm.message_id": "1759140000000000",
            "google.c.sender.id": "000000000000",
            "google.c.fid": "fid-placeholder",
            "google.c.a.e": "1",
        ]
    }

}
