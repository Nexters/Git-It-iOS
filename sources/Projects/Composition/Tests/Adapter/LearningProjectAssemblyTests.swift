import Foundation
import Testing

@testable import CompositionAdapter
@testable import DataLearningProject
@testable import DomainLearningProject

// MARK: - LearningProjectAssemblyTests

@Suite("LearningProjectAssembly")
struct LearningProjectAssemblyTests {

    @Test
    func `live 그래프 생성이 성공하고 노출 property가 모두 UseCase Protocol 타입이다`() throws {
        let assembly = LearningProjectAssembly(baseURL: try #require(URL(string: "https://api.git-it.example.com")))

        _ = assembly.fetchLearningProjects as any FetchLearningProjectsUseCase
        _ = assembly.fetchLearningProjectDetail as any FetchLearningProjectDetailUseCase
        _ = assembly.createLearningProject as any CreateLearningProjectUseCase
        _ = assembly.deleteLearningProject as any DeleteLearningProjectUseCase
    }

}

// MARK: - LearningProjectRepositoryAdapterTests

@Suite("LearningProjectRepositoryAdapter")
struct LearningProjectRepositoryAdapterTests {

    @Test
    func `목록 응답 DTO를 Domain 모델로 변환하고 표기를 뒤집지 않는다`() async throws {
        let remote = StubProjectRemote(fetchProjectsResult: .success(ProjectListResponseDTO(
            items: [
                ProjectListItemDTO(
                    projectID: "project-1",
                    repositoryName: "repo",
                    repositoryImageURL: nil,
                    techStack: ["Swift"],
                    currentSetLabel: "Set 1",
                    currentSetTitle: "title",
                    nextSetID: "set-1",
                    nextQuestionID: "question-1",
                    overallProgressPercent: 40,
                )
            ],
            hasNext: true,
        )))
        let adapter = LearningProjectRepositoryAdapter(remote: remote)

        let page = try await adapter.fetchProjects(page: 0, size: 10)

        #expect(page.items.first?.projectID == "project-1")
        #expect(page.items.first?.nextSetID == "set-1")
        #expect(page.hasNext)
    }

    @Test
    func `상세 응답 DTO를 Domain 모델로 변환한다`() async throws {
        let remote = StubProjectRemote(fetchProjectDetailResult: .success(ProjectDetailResponseDTO(
            projectID: "project-1",
            repositoryURL: "https://github.com/owner/repo",
            repositoryName: "repo",
            repositoryImageURL: nil,
            starCount: 3,
            techStack: [],
            overallProgressPercent: 40,
            nextQuestionID: "question-1",
            sets: [],
        )))
        let adapter = LearningProjectRepositoryAdapter(remote: remote)

        let detail = try await adapter.fetchProjectDetail(projectID: "project-1")

        #expect(detail.projectID == "project-1")
        #expect(detail.repositoryURL == "https://github.com/owner/repo")
    }

    @Test
    func `등록 요청을 Data DTO로 위임하고 응답을 Domain 등록 결과로 변환한다`() async throws {
        let remote = StubProjectRemote(registerProjectResult: .success(RegisterProjectResponseDTO(
            projectID: "project-1",
            status: "ready",
        )))
        let adapter = LearningProjectRepositoryAdapter(remote: remote)

        let registration = try await adapter.register(githubRepoURL: "https://github.com/owner/repo", quizLevel: .l1)

        #expect(registration.projectID == "project-1")
        #expect(registration.status == .ready)
        #expect(await remote.recordedRequests() == [.registerProject(githubRepoURL: "https://github.com/owner/repo")])
    }

    @Test
    func `Data 오류를 Domain 오류로 변환한다`() async throws {
        let remote = StubProjectRemote(fetchProjectDetailResult: .failure(.projectUnavailable))
        let adapter = LearningProjectRepositoryAdapter(remote: remote)

        await #expect(throws: LearningProjectError.notFound) {
            try await adapter.fetchProjectDetail(projectID: "missing")
        }
    }

}

// MARK: - StubProjectRemote

private actor StubProjectRemote: ProjectRemote {

    // MARK: Lifecycle

    init(
        registerProjectResult: Result<RegisterProjectResponseDTO, DataLearningProjectError> = .failure(.unexpectedStatus),
        fetchProjectsResult: Result<ProjectListResponseDTO, DataLearningProjectError> = .failure(.unexpectedStatus),
        fetchProjectDetailResult: Result<ProjectDetailResponseDTO, DataLearningProjectError> = .failure(.unexpectedStatus),
    ) {
        self.registerProjectResult = registerProjectResult
        self.fetchProjectsResult = fetchProjectsResult
        self.fetchProjectDetailResult = fetchProjectDetailResult
    }

    // MARK: Internal

    enum Call: Equatable, Sendable {
        case registerProject(githubRepoURL: String)
        case fetchProjects
        case fetchProjectDetail
        case deleteProject
    }

    func registerProject(_ request: RegisterProjectRequestDTO) async throws -> RegisterProjectResponseDTO {
        calls.append(.registerProject(githubRepoURL: request.githubRepoURL))
        return try registerProjectResult.get()
    }

    func fetchProjects(
        page _: Int,
        size _: Int,
    ) async throws -> ProjectListResponseDTO {
        calls.append(.fetchProjects)
        return try fetchProjectsResult.get()
    }

    func fetchProjectDetail(projectID _: String) async throws -> ProjectDetailResponseDTO {
        calls.append(.fetchProjectDetail)
        return try fetchProjectDetailResult.get()
    }

    func deleteProject(projectID _: String) async throws {
        calls.append(.deleteProject)
    }

    func recordedRequests() -> [Call] {
        calls
    }

    // MARK: Private

    private let registerProjectResult: Result<RegisterProjectResponseDTO, DataLearningProjectError>
    private let fetchProjectsResult: Result<ProjectListResponseDTO, DataLearningProjectError>
    private let fetchProjectDetailResult: Result<ProjectDetailResponseDTO, DataLearningProjectError>
    private var calls = [Call]()

}
