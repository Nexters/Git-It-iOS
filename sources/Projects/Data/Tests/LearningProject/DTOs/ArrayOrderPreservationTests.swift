import Foundation
import Testing

@testable import DataLearningProject

@Suite("서버 응답 배열 순서 보존")
struct ArrayOrderPreservationTests {

    @Test
    func `ProjectDetailResponseDTO의 sets는 서버 응답 순서를 유지한다`() throws {
        let json = Data(#"""
            {
              "projectId": "project-1",
              "repositoryUrl": "https://github.com/example/repo",
              "repositoryName": "repo",
              "repositoryImageUrl": null,
              "starCount": 0,
              "techStack": [],
              "overallProgressPercent": 0,
              "nextQuestionId": null,
              "sets": [
                {"setId": "set-3", "label": "3", "title": "Third", "problemCount": 3, "completedCount": 0},
                {"setId": "set-1", "label": "1", "title": "First", "problemCount": 3, "completedCount": 0},
                {"setId": "set-2", "label": "2", "title": "Second", "problemCount": 3, "completedCount": 0}
              ]
            }
            """#.utf8)

        let detail = try JSONDecoder().decode(ProjectDetailResponseDTO.self, from: json)

        #expect(detail.sets.map(\.setID) == ["set-3", "set-1", "set-2"])
    }

    @Test
    func `LearningSetResponseDTO의 questions와 choices는 서버 응답 순서를 유지한다`() throws {
        let json = Data(#"""
            {
              "setId": "set-1",
              "title": "Basics",
              "description": "",
              "orientation": "horizontal",
              "level": "L1",
              "questions": [
                {
                  "questionId": "question-2",
                  "format": "multipleChoice",
                  "text": "질문2",
                  "choices": ["C", "A", "B"],
                  "sources": [],
                  "myAnswer": null
                },
                {
                  "questionId": "question-1",
                  "format": "multipleChoice",
                  "text": "질문1",
                  "choices": ["Z", "X", "Y"],
                  "sources": [],
                  "myAnswer": null
                }
              ]
            }
            """#.utf8)

        let set = try JSONDecoder().decode(LearningSetResponseDTO.self, from: json)

        #expect(set.questions.map(\.questionID) == ["question-2", "question-1"])
        #expect(set.questions[0].choices == ["C", "A", "B"])
        #expect(set.questions[1].choices == ["Z", "X", "Y"])
    }

}
