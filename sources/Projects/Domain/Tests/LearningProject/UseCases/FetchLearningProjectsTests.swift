import Testing

@testable import DomainLearningProject

// MARK: - FetchLearningProjectsTests

@Suite("FetchLearningProjects")
struct FetchLearningProjectsTests {
    @Test
    func `진행률과 다음 세트 및 다음 질문 정보를 그대로 반환한다`() async throws {
        let summary = LearningProjectSummary(
            projectID: "project-1",
            repositoryName: "repo",
            repositoryImageURL: nil,
            techStack: ["Swift"],
            currentSetLabel: "Set 2",
            currentSetTitle: "Concurrency",
            nextSetID: "set-2",
            nextQuestionID: "question-5",
            overallProgressPercent: 40,
        )
        let page = LearningProjectPage(items: [summary], hasNext: true)
        let fetchLearningProjects = FetchLearningProjects(
            repository: FetchLearningProjectsRepository(behavior: .succeed(page))
        )

        let result = try await fetchLearningProjects()

        #expect(result == page)
    }

    @Test
    func `서버가 반환한 항목 수를 그대로 유지하고 재필터링하지 않는다`() async throws {
        let items = [
            LearningProjectSummary(
                projectID: "project-1",
                repositoryName: "repo-1",
                repositoryImageURL: nil,
                techStack: [],
                currentSetLabel: "Set 1",
                currentSetTitle: "title",
                nextSetID: "set-1",
                nextQuestionID: "question-1",
                overallProgressPercent: 10,
            ),
            LearningProjectSummary(
                projectID: "project-2",
                repositoryName: "repo-2",
                repositoryImageURL: nil,
                techStack: [],
                currentSetLabel: "Set 1",
                currentSetTitle: "title",
                nextSetID: "set-1",
                nextQuestionID: "question-1",
                overallProgressPercent: 90,
            ),
        ]
        let page = LearningProjectPage(items: items, hasNext: false)
        let fetchLearningProjects = FetchLearningProjects(
            repository: FetchLearningProjectsRepository(behavior: .succeed(page))
        )

        let result = try await fetchLearningProjects()

        #expect(result.items.count == items.count)
    }

    @Test
    func `미인증 오류를 그대로 전파한다`() async throws {
        let fetchLearningProjects = FetchLearningProjects(
            repository: FetchLearningProjectsRepository(behavior: .fail(.unauthorized))
        )

        await #expect(throws: LearningProjectError.unauthorized) {
            try await fetchLearningProjects()
        }
    }
}

// MARK: - FetchLearningProjectsRepository

private actor FetchLearningProjectsRepository: LearningProjectRepository {

    // MARK: Lifecycle

    init(behavior: Behavior) {
        self.behavior = behavior
    }

    // MARK: Internal

    enum Behavior: Sendable {
        case succeed(LearningProjectPage)
        case fail(LearningProjectError)
    }

    func register(
        githubRepoURL _: String,
        quizLevel _: QuizLevel,
    ) async throws -> ProjectRegistrationReceipt {
        throw LearningProjectError.unexpected
    }

    func fetchProjects(
        page _: Int,
        size _: Int,
    ) async throws -> LearningProjectPage {
        switch behavior {
        case .succeed(let page):
            return page

        case .fail(let error):
            throw error
        }
    }

    func fetchProjectDetail(projectID _: String) async throws -> LearningProjectDetail {
        throw LearningProjectError.unexpected
    }

    func deleteProject(projectID _: String) async throws {
        throw LearningProjectError.unexpected
    }

    // MARK: Private

    private let behavior: Behavior

}
