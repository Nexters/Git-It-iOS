import Foundation
import Testing

@testable import DataLearningProject

@Suite("QuizGenerationRemote 계약")
struct LearningProjectGenerationContractTests {

    @Test
    func `생성 상태를 조회한다`() async throws {
        let remote = LearningProjectRemoteProbe()

        let response = try await remote.fetchGenerationStatus(projectID: "project-1")

        #expect(response.status == "COMPLETED")
        #expect(await remote.recordedCalls() == [.fetchGenerationStatus])
    }

    @Test
    func `알려지지 않은 status raw value도 decoding 실패 없이 보존한다`() throws {
        let json = Data(#"{"status":"UNKNOWN_FUTURE_STATE"}"#.utf8)

        let response = try JSONDecoder().decode(QuizGenerationStatusResponseDTO.self, from: json)

        #expect(response.status == "UNKNOWN_FUTURE_STATE")
    }

    @Test
    func `생성 재시도를 호출한다`() async throws {
        let remote = LearningProjectRemoteProbe()

        try await remote.retryQuizGeneration(projectID: "project-1")

        #expect(await remote.recordedCalls() == [.retryQuizGeneration])
    }

    @Test
    func `409 QUIZ-007은 generationRetryUnavailable로 변환되고 다른 오류와 혼동되지 않는다`() {
        let serverError = ServerAPIError(httpStatus: 409, code: "QUIZ-007", message: nil, fieldErrors: nil)

        let error = DataLearningProjectError(from: serverError)

        #expect(error == .generationRetryUnavailable)
        #expect(error != .temporarilyUnavailable)
        #expect(error != .unexpectedStatus)
    }

}
