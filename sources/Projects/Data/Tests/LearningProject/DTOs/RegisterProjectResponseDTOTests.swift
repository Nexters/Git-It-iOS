import Foundation
import Testing

@testable import DataLearningProject

@Suite("RegisterProjectResponseDTO")
struct RegisterProjectResponseDTOTests {
    @Test
    func `RegisterProjectResponse 예시를 디코딩한다`() throws {
        let json = """
            {
                "projectId": "68a1f2c3d4e5f6a7b8c9d0e1",
                "status": "READY"
            }
            """

        let dto = try JSONDecoder().decode(RegisterProjectResponseDTO.self, from: Data(json.utf8))

        #expect(dto.projectId == "68a1f2c3d4e5f6a7b8c9d0e1")
        #expect(dto.status == .ready)
    }

    @Test
    func `quizLevel 필드가 없어도 디코딩된다`() throws {
        let json = """
            {"projectId": "project-1", "status": "COMPLETED"}
            """

        let dto = try JSONDecoder().decode(RegisterProjectResponseDTO.self, from: Data(json.utf8))

        #expect(dto.status == .completed)
    }
}
