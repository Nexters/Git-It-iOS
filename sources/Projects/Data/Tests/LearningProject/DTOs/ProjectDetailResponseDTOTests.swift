import Foundation
import Testing

@testable import DataLearningProject

@Suite("ProjectDetailResponseDTO")
struct ProjectDetailResponseDTOTests {
    @Test
    func `GET api v1 projects projectId 예시 응답을 디코딩한다`() throws {
        let json = """
            {
                "projectId": "68a1f2c3d4e5f6a7b8c9d0e1",
                "repositoryUrl": "https://github.com/nexters/nexters",
                "repositoryName": "nexters",
                "repositoryImageUrl": "https://avatars.githubusercontent.com/u/1",
                "starCount": 3600,
                "techStack": ["Kotlin", "Compose", "Coroutines"],
                "overallProgressPercent": 28,
                "nextQuestionId": "q3",
                "sets": [
                    {
                        "setId": "set1",
                        "label": "Set 1",
                        "title": "Set 1 title",
                        "problemCount": 3,
                        "completedCount": 2
                    },
                    {
                        "setId": "set2",
                        "label": "Set 2",
                        "title": "Set 2 title",
                        "problemCount": 4,
                        "completedCount": 0
                    }
                ]
            }
            """

        let dto = try JSONDecoder().decode(ProjectDetailResponseDTO.self, from: Data(json.utf8))

        #expect(dto.projectId == "68a1f2c3d4e5f6a7b8c9d0e1")
        #expect(dto.repositoryUrl == "https://github.com/nexters/nexters")
        #expect(dto.starCount == 3600)
        #expect(dto.nextQuestionId == "q3")
        #expect(dto.sets.count == 2)
        #expect(dto.sets[0].setId == "set1")
        #expect(dto.sets[0].completedCount == 2)
        #expect(dto.sets[1].setId == "set2")
        #expect(dto.sets[1].problemCount == 4)
    }
}
