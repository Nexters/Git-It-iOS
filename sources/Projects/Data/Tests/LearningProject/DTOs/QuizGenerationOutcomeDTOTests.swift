import Testing

@testable import DataLearningProject

// MARK: - QuizGenerationOutcomeDTOTests

@Suite("QuizGenerationOutcomeDTO 디코딩")
struct QuizGenerationOutcomeDTOTests {

    @Test
    func `completed 상태 payload를 디코딩한다`() {
        let dto = QuizGenerationOutcomeDTO(rawPayload: ["projectId": "project-1", "status": "completed"])

        #expect(dto == QuizGenerationOutcomeDTO(projectID: "project-1", status: .completed))
    }

    @Test
    func `failed 상태 payload를 디코딩한다`() {
        let dto = QuizGenerationOutcomeDTO(rawPayload: ["projectId": "project-2", "status": "failed"])

        #expect(dto == QuizGenerationOutcomeDTO(projectID: "project-2", status: .failed))
    }

    @Test
    func `알 수 없는 status 값은 디코딩에 실패한다`() {
        let dto = QuizGenerationOutcomeDTO(rawPayload: ["projectId": "project-1", "status": "pending"])

        #expect(dto == nil)
    }

    @Test
    func `projectId 키가 없으면 디코딩에 실패한다`() {
        let dto = QuizGenerationOutcomeDTO(rawPayload: ["status": "completed"])

        #expect(dto == nil)
    }

    @Test
    func `status 키가 없으면 디코딩에 실패한다`() {
        let dto = QuizGenerationOutcomeDTO(rawPayload: ["projectId": "project-1"])

        #expect(dto == nil)
    }

}
