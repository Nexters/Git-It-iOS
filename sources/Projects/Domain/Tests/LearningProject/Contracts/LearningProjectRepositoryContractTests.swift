import Testing

@testable import DomainLearningProject

// MARK: - LearningProjectRepositoryContractTests

@Suite("LearningProjectRepository 계약")
struct LearningProjectRepositoryContractTests {
    @Test
    func `등록과 목록 및 상세 조회와 삭제만 제공한다`() async throws {
        let registration = LearningProjectRegistration(
            projectID: "project-1",
            status: .ready,
            quizLevel: .l1,
        )
        let page = LearningProjectPage(items: [], hasNext: false)
        let detail = LearningProjectDetail(
            projectID: "project-1",
            repositoryURL: "https://github.com/owner/repo",
            repositoryName: "repo",
            repositoryImageURL: nil,
            starCount: 0,
            techStack: [],
            overallProgressPercent: 0,
            nextQuestionID: nil,
            sets: [],
        )
        let repository = LearningProjectRepositoryContractProbe(
            registration: registration,
            page: page,
            detail: detail,
        )

        let registeredResult = try await repository.register(githubRepoURL: "https://github.com/owner/repo", quizLevel: .l1)
        let fetchedPage = try await repository.fetchProjects(page: 0, size: 10)
        let fetchedDetail = try await repository.fetchProjectDetail(projectID: "project-1")
        try await repository.deleteProject(projectID: "project-1")

        #expect(registeredResult == registration)
        #expect(fetchedPage == page)
        #expect(fetchedDetail == detail)
        #expect(
            await repository.recordedCalls() == [
                .register(githubRepoURL: "https://github.com/owner/repo", quizLevel: .l1),
                .fetchProjects(page: 0, size: 10),
                .fetchProjectDetail(projectID: "project-1"),
                .deleteProject(projectID: "project-1"),
            ]
        )
    }
}

// MARK: - LearningProjectRepositoryContractProbe

private actor LearningProjectRepositoryContractProbe: LearningProjectRepository {

    // MARK: Lifecycle

    init(
        registration: LearningProjectRegistration,
        page: LearningProjectPage,
        detail: LearningProjectDetail,
    ) {
        self.registration = registration
        self.page = page
        self.detail = detail
    }

    // MARK: Internal

    enum Call: Equatable, Sendable {
        case register(githubRepoURL: String, quizLevel: QuizLevel)
        case fetchProjects(page: Int, size: Int)
        case fetchProjectDetail(projectID: String)
        case deleteProject(projectID: String)
    }

    func register(
        githubRepoURL: String,
        quizLevel: QuizLevel,
    ) async throws -> LearningProjectRegistration {
        calls.append(.register(githubRepoURL: githubRepoURL, quizLevel: quizLevel))
        return registration
    }

    func fetchProjects(
        page: Int,
        size: Int,
    ) async throws -> LearningProjectPage {
        calls.append(.fetchProjects(page: page, size: size))
        return self.page
    }

    func fetchProjectDetail(projectID: String) async throws -> LearningProjectDetail {
        calls.append(.fetchProjectDetail(projectID: projectID))
        return detail
    }

    func deleteProject(projectID: String) async throws {
        calls.append(.deleteProject(projectID: projectID))
    }

    func recordedCalls() -> [Call] {
        calls
    }

    // MARK: Private

    private let registration: LearningProjectRegistration
    private let page: LearningProjectPage
    private let detail: LearningProjectDetail
    private var calls = [Call]()

}
