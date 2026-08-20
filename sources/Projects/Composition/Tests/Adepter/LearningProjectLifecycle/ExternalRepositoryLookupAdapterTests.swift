import Testing

@testable import CompositionAdepter
@testable import DataLearningProject
@testable import DomainLearningProject

// MARK: - ExternalRepositoryLookupAdapterTests

@Suite("ExternalRepositoryLookupAdapter")
struct ExternalRepositoryLookupAdapterTests {
    @Test
    func `GitHubRepositoryResponseDTO를 ExternalRepository로 정확히 변환한다`() async throws {
        let dto = GitHubRepositoryResponseDTO(
            fullName: "owner/repo",
            htmlURL: "https://github.com/owner/repo",
            ownerAvatarURL: "https://avatars.githubusercontent.com/u/1",
            starCount: 42,
            language: "Swift",
            topics: ["ios", "swift"],
        )
        let adapter = ExternalRepositoryLookupAdapter(remote: LookupAdapterFakeRemote(.succeed(dto)))

        let result = try await adapter.repository(owner: "owner", name: "repo")

        #expect(result.canonicalURL == "https://github.com/owner/repo")
        #expect(result.ownerName == "owner")
        #expect(result.repositoryName == "repo")
        #expect(result.imageURL == "https://avatars.githubusercontent.com/u/1")
        #expect(result.starCount == 42)
        #expect(result.techStack == ["ios", "swift"])
    }

    @Test
    func `offline 오류를 그대로 전파한다`() async throws {
        let adapter = ExternalRepositoryLookupAdapter(remote: LookupAdapterFakeRemote(.fail(.offline)))

        await #expect(throws: ExternalRepositoryError.offline) {
            try await adapter.repository(owner: "owner", name: "repo")
        }
    }

    @Test
    func `other 오류를 그대로 전파한다`() async throws {
        let adapter = ExternalRepositoryLookupAdapter(remote: LookupAdapterFakeRemote(.fail(.other)))

        await #expect(throws: ExternalRepositoryError.other) {
            try await adapter.repository(owner: "owner", name: "repo")
        }
    }
}

// MARK: - LookupAdapterFakeRemote

private struct LookupAdapterFakeRemote: ExternalRepositoryRemote {

    // MARK: Lifecycle

    init(_ behavior: Behavior) {
        self.behavior = behavior
    }

    // MARK: Internal

    enum Behavior: Sendable {
        case succeed(GitHubRepositoryResponseDTO)
        case fail(DataExternalRepositoryError)
    }

    func repository(
        owner _: String,
        name _: String,
    ) async throws -> GitHubRepositoryResponseDTO {
        switch behavior {
        case .succeed(let dto):
            return dto

        case .fail(let error):
            throw error
        }
    }

    // MARK: Private

    private let behavior: Behavior

}
