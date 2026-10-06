import Foundation
import Testing

@testable import DataExternalRepository

@Suite("GitHub Repository 응답 DTO")
struct GitHubRepositoryResponseDTOTests {

    // MARK: Internal

    @Test
    func `최소 응답과 추가 wire 필드에서 서비스 필요 데이터만 보존한다`() throws {
        let response = try decode("""
            { "html_url": "https://github.com/facebook/react", "name": "react", "owner": { "login": "facebook", "avatar_url": "https://avatars.githubusercontent.com/u/69631" }, "stargazers_count": 240000, "topics": ["javascript", "ui"], "full_name": "facebook/react", "language": "JavaScript" }
            """)

        #expect(response == GitHubRepositoryResponseDTO(
            htmlURL: "https://github.com/facebook/react",
            ownerLogin: "facebook",
            repositoryName: "react",
            ownerAvatarURL: "https://avatars.githubusercontent.com/u/69631",
            starCount: 240000,
            topics: ["javascript", "ui"],
        ))
        #expect(Set(Mirror(reflecting: response).children.compactMap(\.label)) == [
            "htmlURL",
            "ownerLogin",
            "repositoryName",
            "ownerAvatarURL",
            "starCount",
            "topics",
        ])
    }

    @Test(arguments: [
        "{ \"html_url\": \"https://github.com/facebook/react\", \"name\": \"react\", \"owner\": { \"login\": \"facebook\" }, \"stargazers_count\": 0 }",
        "{ \"html_url\": \"https://github.com/facebook/react\", \"name\": \"react\", \"owner\": { \"login\": \"facebook\", \"avatar_url\": null }, \"stargazers_count\": 0, \"topics\": null }",
        "{ \"html_url\": \"https://github.com/facebook/react\", \"name\": \"react\", \"owner\": { \"login\": \"facebook\" }, \"stargazers_count\": 0, \"topics\": [] }",
    ])
    func `선택 avatar와 topics는 누락 null 및 빈 배열을 허용한다`(_ fixture: String) throws {
        let response = try decode(fixture)

        #expect(response.ownerAvatarURL == nil)
        #expect(response.starCount == 0)
        #expect(response.topics == [])
    }

    @Test(arguments: [
        "{ \"html_url\": \"https://github.com/facebook/react\", \"stargazers_count\": 1 }",
        "{ \"html_url\": \"https://github.com/facebook/react\", \"owner\": null, \"stargazers_count\": 1 }",
        "{ \"owner\": {}, \"stargazers_count\": 1 }",
        "{ \"html_url\": 1, \"owner\": {}, \"stargazers_count\": 1 }",
        "{ \"html_url\": \"https://github.com/facebook/react\", \"owner\": {}, \"stargazers_count\": null }",
        "{ \"html_url\": \"https://github.com/facebook/react\", \"owner\": {}, \"stargazers_count\": \"1\" }",
        "{ \"html_url\": \"https://github.com/facebook/react\", \"name\": \"react\", \"owner\": {}, \"stargazers_count\": 1 }",
        "{ \"html_url\": \"https://github.com/facebook/react\", \"owner\": { \"login\": \"facebook\" }, \"stargazers_count\": 1 }",
    ])
    func `필수 owner와 필수 필드의 누락 null 및 잘못된 타입은 실패한다`(_ fixture: String) {
        #expect(throws: DecodingError.self) {
            try decode(fixture)
        }
    }

    // MARK: Private

    private func decode(_ fixture: String) throws -> GitHubRepositoryResponseDTO {
        try JSONDecoder().decode(GitHubRepositoryResponseDTO.self, from: Data(fixture.utf8))
    }

}
