import Testing

@testable import DataLearningProject

// MARK: - LearningProjectRemoteContractTests

@Suite("LearningProjectRemote 계약")
struct LearningProjectRemoteContractTests {
    @Test
    func `등록과 목록 및 상세 조회와 삭제만 제공한다`() async throws {
        let registerResponse = RegisterProjectResponseDTO(projectId: "project-1", status: .ready)
        let listResponse = ProjectListResponseDTO(items: [], hasNext: false)
        let detailResponse = ProjectDetailResponseDTO(
            projectId: "project-1",
            repositoryUrl: "https://github.com/owner/repo",
            repositoryName: "repo",
            repositoryImageUrl: nil,
            starCount: 0,
            techStack: [],
            overallProgressPercent: 0,
            nextQuestionId: nil,
            sets: [],
        )
        let remote = LearningProjectRemoteContractProbe(
            registerResponse: registerResponse,
            listResponse: listResponse,
            detailResponse: detailResponse,
        )
        let request = RegisterProjectRequestDTO(githubRepoUrl: "https://github.com/owner/repo", quizLevel: .l1)

        let registeredResult = try await remote.registerProject(request)
        let fetchedList = try await remote.fetchProjects(page: 0, size: 10)
        let fetchedDetail = try await remote.fetchProjectDetail(projectId: "project-1")
        try await remote.deleteProject(projectId: "project-1")

        #expect(registeredResult == registerResponse)
        #expect(fetchedList == listResponse)
        #expect(fetchedDetail == detailResponse)
        #expect(
            await remote.recordedCalls() == [
                .registerProject(request),
                .fetchProjects(page: 0, size: 10),
                .fetchProjectDetail(projectId: "project-1"),
                .deleteProject(projectId: "project-1"),
            ]
        )
    }
}

// MARK: - LearningProjectRemoteContractProbe

private actor LearningProjectRemoteContractProbe: LearningProjectRemote {

    // MARK: Lifecycle

    init(
        registerResponse: RegisterProjectResponseDTO,
        listResponse: ProjectListResponseDTO,
        detailResponse: ProjectDetailResponseDTO,
    ) {
        self.registerResponse = registerResponse
        self.listResponse = listResponse
        self.detailResponse = detailResponse
    }

    // MARK: Internal

    enum Call: Equatable, Sendable {
        case registerProject(RegisterProjectRequestDTO)
        case fetchProjects(page: Int, size: Int)
        case fetchProjectDetail(projectId: String)
        case deleteProject(projectId: String)
    }

    func registerProject(_ request: RegisterProjectRequestDTO) async throws -> RegisterProjectResponseDTO {
        calls.append(.registerProject(request))
        return registerResponse
    }

    func fetchProjects(
        page: Int,
        size: Int,
    ) async throws -> ProjectListResponseDTO {
        calls.append(.fetchProjects(page: page, size: size))
        return listResponse
    }

    func fetchProjectDetail(projectId: String) async throws -> ProjectDetailResponseDTO {
        calls.append(.fetchProjectDetail(projectId: projectId))
        return detailResponse
    }

    func deleteProject(projectId: String) async throws {
        calls.append(.deleteProject(projectId: projectId))
    }

    func recordedCalls() -> [Call] {
        calls
    }

    // MARK: Private

    private let registerResponse: RegisterProjectResponseDTO
    private let listResponse: ProjectListResponseDTO
    private let detailResponse: ProjectDetailResponseDTO
    private var calls = [Call]()

}
