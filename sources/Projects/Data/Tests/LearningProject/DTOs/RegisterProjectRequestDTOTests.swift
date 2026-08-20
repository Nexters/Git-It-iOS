import Foundation
import Testing

@testable import DataLearningProject

@Suite("RegisterProjectRequestDTO")
struct RegisterProjectRequestDTOTests {
    @Test
    func `RegisterProjectRequest 스키마와 동일한 키로 인코딩된다`() throws {
        let request = RegisterProjectRequestDTO(
            githubRepoUrl: "https://github.com/Nexters/Git-it-Server",
            quizLevel: .l2,
        )

        let data = try JSONEncoder().encode(request)
        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(decoded?["githubRepoUrl"] as? String == "https://github.com/Nexters/Git-it-Server")
        #expect(decoded?["quizLevel"] as? String == "L2")
    }
}
