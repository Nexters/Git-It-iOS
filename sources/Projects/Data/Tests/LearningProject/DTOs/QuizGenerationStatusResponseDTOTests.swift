import Foundation
import Testing

@testable import DataLearningProject

@Suite("QuizGenerationStatusResponseDTO")
struct QuizGenerationStatusResponseDTOTests {

    @Test
    func `알려지지 않은 status raw value도 디코딩 실패 없이 보존한다`() throws {
        let json = Data(#"{"status":"UNKNOWN_FUTURE_STATE"}"#.utf8)

        let response = try JSONDecoder().decode(
            QuizGenerationStatusResponseDTO.self,
            from: json,
        )

        #expect(response.status == "UNKNOWN_FUTURE_STATE")
    }

}
