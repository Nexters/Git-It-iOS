import Foundation
import Testing

@testable import DataLearningProject

@Suite("LearningSetRemote 계약")
struct LearningProjectLearningSetContractTests {

    @Test
    func `학습 세트를 조회한다`() async throws {
        let remote = LearningProjectRemoteProbe()

        let response = try await remote.fetchLearningSet(projectID: "project-1", setID: "set-1")

        #expect(response.setID == "set-1")
        #expect(await remote.recordedCalls() == [.fetchLearningSet])
    }

    @Test
    func `객관식 질문은 choices와 myAnswer를 디코딩한다`() throws {
        let json = Data(#"""
            {
              "questionId": "question-1",
              "format": "multipleChoice",
              "text": "질문",
              "choices": ["A", "B", "C"],
              "sources": [],
              "myAnswer": {
                "selectedIndex": 1,
                "text": null,
                "correct": true,
                "answeredAt": "2026-08-21T00:00:00Z"
              }
            }
            """#.utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let question = try decoder.decode(QuestionResponseDTO.self, from: json)

        #expect(question.choices == ["A", "B", "C"])
        #expect(question.myAnswer?.selectedIndex == 1)
        #expect(question.myAnswer?.correct == true)
    }

    @Test
    func `서술형 질문의 myAnswer가 nil이어도 decoding에 실패하지 않는다`() throws {
        let json = Data(#"""
            {
              "questionId": "question-2",
              "format": "essay",
              "text": "질문",
              "choices": [],
              "sources": [],
              "myAnswer": null
            }
            """#.utf8)

        let question = try JSONDecoder().decode(QuestionResponseDTO.self, from: json)

        #expect(question.myAnswer == nil)
    }

}
