import Foundation
import Testing
@testable import CompositionAdapter
@testable import DataExternalRepository
@testable import DomainLearningProject

// MARK: - ExternalRepositoryLookupAdapterTests

@Suite("ExternalRepositoryLookupAdapter")
struct ExternalRepositoryLookupAdapterTests {

    @Test
    func `GitHub 응답 DTO를 Domain 모델로 변환한다`() async throws {
        let remote = StubExternalRepositoryRemote(result: .success(GitHubRepositoryResponseDTO(
            htmlURL: "https://github.com/facebook/react",
            ownerLogin: "facebook",
            repositoryName: "react",
            ownerAvatarURL: "https://avatar",
            starCount: 10,
            topics: ["swift"],
        )))
        let adapter = ExternalRepositoryLookupAdapter(remote: remote)

        let repository = try await adapter.repository(owner: "Facebook", name: "React")

        #expect(repository.canonicalURL == "https://github.com/facebook/react")
        #expect(repository.ownerName == "facebook")
        #expect(repository.repositoryName == "react")
        #expect(repository.starCount == 10)
    }

    @Test
    func `Data 오류를 Domain 오류로 변환한다`() async throws {
        let remote = StubExternalRepositoryRemote(result: .failure(.offline))
        let adapter = ExternalRepositoryLookupAdapter(remote: remote)

        await #expect(throws: ExternalRepositoryError.offline) {
            try await adapter.repository(owner: "facebook", name: "react")
        }
    }

}

// MARK: - StubExternalRepositoryRemote

private struct StubExternalRepositoryRemote: ExternalRepositoryRemote {
    let result: Result<GitHubRepositoryResponseDTO, DataExternalRepositoryError>

    func repository(_: GitHubRepositoryRequest) async throws -> GitHubRepositoryResponseDTO {
        try result.get()
    }
}
