import Testing

@testable import DataExternalRepository

@Suite("GitHubRepositoryURLParser")
struct GitHubRepositoryURLParserTests {
    @Test(arguments: [
        "https://github.com/owner/repo",
        "github.com/owner/repo",
        "www.github.com/owner/repo",
        "http://github.com/owner/repo",
        "http://www.github.com/owner/repo",
        "https://www.github.com/owner/repo",
        "HTTPS://GitHub.com/owner/repo",
        "  https://github.com/owner/repo  ",
    ])
    func `scheme·www·공백 조합이 달라도 같은 owner와 repo로 해석한다`(_ url: String) {
        let location = GitHubRepositoryURLParser().location(from: url)

        #expect(location == ExternalRepositoryLocation(owner: "owner", name: "repo"))
    }

    @Test
    func `git 접미사와 뒤따르는 경로를 떼고 저장소 이름만 남긴다`() {
        let parser = GitHubRepositoryURLParser()

        #expect(parser.location(from: "https://github.com/owner/repo.git")?.name == "repo")
        #expect(parser.location(from: "https://github.com/owner/repo/tree/main")?.name == "repo")
    }

    @Test(arguments: [
        "",
        "   ",
        "https://gitlab.com/owner/repo",
        "https://github.com/owner",
        "https://example.com",
        "not a url",
    ])
    func `GitHub 저장소를 가리키지 않는 입력은 해석하지 않는다`(_ url: String) {
        #expect(GitHubRepositoryURLParser().location(from: url) == nil)
    }
}
