import Foundation
import Testing

@testable import DataLearningProject

@Suite("ProjectListResponseDTO")
struct ProjectListResponseDTOTests {
    @Test
    func `GET api v1 projects 예시 응답을 디코딩한다`() throws {
        let json = """
            {
                "items": [
                    {
                        "projectId": "68a1f2c3d4e5f6a7b8c9d0e1",
                        "repositoryName": "nexters",
                        "repositoryImageUrl": "https://avatars.githubusercontent.com/u/1",
                        "techStack": ["Kotlin", "Compose", "Coroutines"],
                        "currentSetLabel": "Set 1",
                        "currentSetTitle": "Set 1 title",
                        "nextSetId": "set1",
                        "nextQuestionId": "q3",
                        "overallProgressPercent": 28
                    }
                ],
                "hasNext": false
            }
            """

        let dto = try JSONDecoder().decode(ProjectListResponseDTO.self, from: Data(json.utf8))

        #expect(dto.hasNext == false)
        #expect(dto.items.count == 1)

        let item = try #require(dto.items.first)
        #expect(item.projectId == "68a1f2c3d4e5f6a7b8c9d0e1")
        #expect(item.repositoryName == "nexters")
        #expect(item.repositoryImageUrl == "https://avatars.githubusercontent.com/u/1")
        #expect(item.techStack == ["Kotlin", "Compose", "Coroutines"])
        #expect(item.currentSetLabel == "Set 1")
        #expect(item.currentSetTitle == "Set 1 title")
        #expect(item.nextSetId == "set1")
        #expect(item.nextQuestionId == "q3")
        #expect(item.overallProgressPercent == 28)
    }
}
