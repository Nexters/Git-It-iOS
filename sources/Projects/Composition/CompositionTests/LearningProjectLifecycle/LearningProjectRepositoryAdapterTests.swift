import Testing

@testable import Composition
@testable import DataLearningProject
@testable import DomainLearningProject

// MARK: - LearningProjectRepositoryAdapterTests

@Suite("LearningProjectRepositoryAdapter")
struct LearningProjectRepositoryAdapterTests {
    @Test
    func `register 성공 응답을 Domain 모델로 변환하고 quizLevel은 호출값을 보존한다`() async throws {
        let remote = RepositoryAdapterFakeRemote(
            registerResult: .success(RegisterProjectResponseDTO(projectId: "project-1", status: .ready))
        )
        let adapter = LearningProjectRepositoryAdapter(remote: remote)

        let result = try await adapter.register(
            githubRepoUrl: "https://github.com/owner/repo",
            quizLevel: .l2,
        )

        #expect(result.projectId == "project-1")
        #expect(result.status == .ready)
        #expect(result.quizLevel == .l2)
    }

    @Test
    func `fetchProjects 성공 응답을 Domain 모델로 변환한다`() async throws {
        let item = ProjectListItemDTO(
            projectId: "project-1",
            repositoryName: "repo",
            repositoryImageUrl: nil,
            techStack: ["Swift"],
            currentSetLabel: "Set 1",
            currentSetTitle: "title",
            nextSetId: "set-1",
            nextQuestionId: "question-1",
            overallProgressPercent: 10,
        )
        let remote = RepositoryAdapterFakeRemote(
            listResult: .success(ProjectListResponseDTO(items: [item], hasNext: true))
        )
        let adapter = LearningProjectRepositoryAdapter(remote: remote)

        let result = try await adapter.fetchProjects(page: 0, size: 10)

        #expect(result.hasNext == true)
        #expect(result.items.first?.projectId == "project-1")
    }

    @Test
    func `fetchProjectDetail 성공 응답을 Domain 모델로 변환한다`() async throws {
        let set = ProjectSetSummaryDTO(setId: "set-1", label: "Set 1", title: "title", problemCount: 5, completedCount: 2)
        let remote = RepositoryAdapterFakeRemote(
            detailResult: .success(ProjectDetailResponseDTO(
                projectId: "project-1",
                repositoryUrl: "https://github.com/owner/repo",
                repositoryName: "repo",
                repositoryImageUrl: nil,
                starCount: 10,
                techStack: ["Swift"],
                overallProgressPercent: 40,
                nextQuestionId: "question-2",
                sets: [set],
            ))
        )
        let adapter = LearningProjectRepositoryAdapter(remote: remote)

        let result = try await adapter.fetchProjectDetail(projectId: "project-1")

        #expect(result.projectId == "project-1")
        #expect(result.sets.first?.setId == "set-1")
        #expect(result.nextSet?.setId == "set-1")
    }

    @Test
    func `deleteProject 성공은 오류 없이 완료한다`() async throws {
        let remote = RepositoryAdapterFakeRemote(deleteResult: .success(()))
        let adapter = LearningProjectRepositoryAdapter(remote: remote)

        try await adapter.deleteProject(projectId: "project-1")
    }

    @Test(arguments: [
        (DataLearningProjectError.invalidRequest, LearningProjectError.invalidRequest),
        (.unauthorized, .unauthorized),
        (.notFound, .notFound),
        (.serverError, .unexpected),
        (.unexpected, .unexpected),
    ])
    func `DataLearningProjectError가 대응 LearningProjectError로 변환된다`(
        dataError: DataLearningProjectError,
        expected: LearningProjectError,
    ) async throws {
        let remote = RepositoryAdapterFakeRemote(detailResult: .failure(dataError))
        let adapter = LearningProjectRepositoryAdapter(remote: remote)

        await #expect(throws: expected) {
            try await adapter.fetchProjectDetail(projectId: "project-1")
        }
    }
}

// MARK: - RepositoryAdapterFakeRemote

private struct RepositoryAdapterFakeRemote: LearningProjectRemote {

    // MARK: Lifecycle

    init(
        registerResult: Result<RegisterProjectResponseDTO, DataLearningProjectError> = .failure(.unexpected),
        listResult: Result<ProjectListResponseDTO, DataLearningProjectError> = .failure(.unexpected),
        detailResult: Result<ProjectDetailResponseDTO, DataLearningProjectError> = .failure(.unexpected),
        deleteResult: Result<Void, DataLearningProjectError> = .failure(.unexpected),
    ) {
        self.registerResult = registerResult
        self.listResult = listResult
        self.detailResult = detailResult
        self.deleteResult = deleteResult
    }

    // MARK: Internal

    func registerProject(_: RegisterProjectRequestDTO) async throws -> RegisterProjectResponseDTO {
        try registerResult.get()
    }

    func fetchProjects(
        page _: Int,
        size _: Int,
    ) async throws -> ProjectListResponseDTO {
        try listResult.get()
    }

    func fetchProjectDetail(projectId _: String) async throws -> ProjectDetailResponseDTO {
        try detailResult.get()
    }

    func deleteProject(projectId _: String) async throws {
        try deleteResult.get()
    }

    // MARK: Private

    private let registerResult: Result<RegisterProjectResponseDTO, DataLearningProjectError>
    private let listResult: Result<ProjectListResponseDTO, DataLearningProjectError>
    private let detailResult: Result<ProjectDetailResponseDTO, DataLearningProjectError>
    private let deleteResult: Result<Void, DataLearningProjectError>

}
