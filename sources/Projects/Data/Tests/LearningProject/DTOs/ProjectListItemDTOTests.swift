import Foundation
import Testing

@testable import DataLearningProject

@Suite("ProjectListItemDTO nullable 필드 디코딩")
struct ProjectListItemDTOTests {

    @Test
    func `repositoryImageUrl과 nextSetID, nextQuestionId가 null이어도 decoding에 실패하지 않는다`() throws {
        let json = Data(#"""
            {
              "projectId": "project-1",
              "repositoryName": "repo",
              "repositoryImageUrl": null,
              "techStack": ["Swift"],
              "currentSetLabel": "Set 1",
              "currentSetTitle": "Basics",
              "nextSetId": null,
              "nextQuestionId": null,
              "overallProgressPercent": 0
            }
            """#.utf8)

        let item = try JSONDecoder().decode(ProjectListItemDTO.self, from: json)

        #expect(item.repositoryImageURL == nil)
        #expect(item.nextSetID == nil)
        #expect(item.nextQuestionID == nil)
    }

}
