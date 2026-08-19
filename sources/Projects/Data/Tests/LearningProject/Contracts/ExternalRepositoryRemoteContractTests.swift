import Testing

@testable import DataLearningProject

// MARK: - ExternalRepositoryRemoteContractTests

@Suite("ExternalRepositoryRemote 계약")
struct ExternalRepositoryRemoteContractTests {
    @Test
    func `소유자와 저장소 이름으로 GitHub 응답 DTO 조회만 제공한다`() async throws {
        let expected = GitHubRepositoryResponseDTO(
            fullName: "owner/repo",
            htmlURL: "https://github.com/owner/repo",
            ownerAvatarURL: "https://avatars.githubusercontent.com/u/1",
            starCount: 42,
            language: "Swift",
            topics: ["ios"],
        )
        let remote = ExternalRepositoryRemoteContractProbe(response: expected)

        let result = try await remote.repository(owner: "owner", name: "repo")

        #expect(result == expected)
        #expect(await remote.recordedCalls() == [.repository(owner: "owner", name: "repo")])
    }
}

// MARK: - ExternalRepositoryRemoteContractProbe

private actor ExternalRepositoryRemoteContractProbe: ExternalRepositoryRemote {

    // MARK: Lifecycle

    init(response: GitHubRepositoryResponseDTO) {
        self.response = response
    }

    // MARK: Internal

    enum Call: Equatable, Sendable {
        case repository(owner: String, name: String)
    }

    func repository(
        owner: String,
        name: String,
    ) async throws -> GitHubRepositoryResponseDTO {
        calls.append(.repository(owner: owner, name: name))
        return response
    }

    func recordedCalls() -> [Call] {
        calls
    }

    // MARK: Private

    private let response: GitHubRepositoryResponseDTO
    private var calls = [Call]()

}
