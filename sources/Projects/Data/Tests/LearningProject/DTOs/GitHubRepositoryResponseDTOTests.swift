import Foundation
import Testing

@testable import DataLearningProject

@Suite("GitHubRepositoryResponseDTO")
struct GitHubRepositoryResponseDTOTests {
    @Test
    func `GitHub 저장소 조회 응답 예시를 디코딩한다`() throws {
        let json = """
            {
                "full_name": "Nexters/Git-it-Server",
                "html_url": "https://github.com/Nexters/Git-it-Server",
                "owner": {
                    "avatar_url": "https://avatars.githubusercontent.com/u/1"
                },
                "stargazers_count": 42,
                "language": "Kotlin",
                "topics": ["kotlin", "spring-boot"]
            }
            """

        let dto = try JSONDecoder().decode(GitHubRepositoryResponseDTO.self, from: Data(json.utf8))

        #expect(dto.fullName == "Nexters/Git-it-Server")
        #expect(dto.htmlURL == "https://github.com/Nexters/Git-it-Server")
        #expect(dto.ownerAvatarURL == "https://avatars.githubusercontent.com/u/1")
        #expect(dto.starCount == 42)
        #expect(dto.language == "Kotlin")
        #expect(dto.topics == ["kotlin", "spring-boot"])
    }
}
