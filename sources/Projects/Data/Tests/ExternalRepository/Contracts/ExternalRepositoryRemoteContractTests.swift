import Testing

@testable import DataExternalRepository

// MARK: - ExternalRepositoryRemoteContractTests

@Suite("ExternalRepositoryRemote 계약")
struct ExternalRepositoryRemoteContractTests {
    @Test
    func `성공 시 요청을 한 번 기록하고 DTO를 그대로 반환한다`() async throws {
        let request = GitHubRepositoryRequest(owner: "facebook", repository: "react")
        let response = GitHubRepositoryResponseDTO(
            htmlURL: "https://github.com/facebook/react",
            ownerAvatarURL: nil,
            starCount: 240000,
            topics: ["javascript"],
        )
        let remote = ExternalRepositoryRemoteProbe(result: .success(response))

        let actual = try await remote.repository(request)

        #expect(actual == response)
        #expect(await remote.recordedRequests() == [request])
    }

    @Test(arguments: [DataExternalRepositoryError.offline, .other])
    func `지정된 실패는 성공 DTO 없이 손실 없이 전달한다`(_ expectedError: DataExternalRepositoryError) async {
        let remote = ExternalRepositoryRemoteProbe(result: .failure(expectedError))

        await #expect(throws: expectedError) {
            try await remote.repository(GitHubRepositoryRequest(owner: "facebook", repository: "react"))
        }
    }
}

// MARK: - ExternalRepositoryRemoteProbe

private actor ExternalRepositoryRemoteProbe: ExternalRepositoryRemote {

    // MARK: Lifecycle

    init(result: Result<GitHubRepositoryResponseDTO, DataExternalRepositoryError>) {
        self.result = result
    }

    // MARK: Internal

    func repository(_ request: GitHubRepositoryRequest) async throws -> GitHubRepositoryResponseDTO {
        requests.append(request)
        return try result.get()
    }

    func recordedRequests() -> [GitHubRepositoryRequest] {
        requests
    }

    // MARK: Private

    private let result: Result<GitHubRepositoryResponseDTO, DataExternalRepositoryError>
    private var requests = [GitHubRepositoryRequest]()

}
