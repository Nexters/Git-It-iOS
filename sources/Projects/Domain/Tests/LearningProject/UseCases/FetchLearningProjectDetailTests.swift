import Testing

@testable import DomainLearningProject

// MARK: - FetchLearningProjectDetailTests

@Suite("FetchLearningProjectDetail")
struct FetchLearningProjectDetailTests {
    @Test
    func `진행 중 세트가 있으면 다음 세트가 일치한다`() async throws {
        let inProgressSet = LearningProjectSetProgress(
            setID: "set-2",
            label: "Set 2",
            title: "title",
            problemCount: 5,
            completedCount: 1,
        )
        let detail = makeDetail(sets: [
            LearningProjectSetProgress(setID: "set-1", label: "Set 1", title: "title", problemCount: 5, completedCount: 5),
            inProgressSet,
        ])
        let fetchLearningProjectDetail = FetchLearningProjectDetail(
            repository: FetchLearningProjectDetailRepository(behavior: .succeed(detail))
        )

        let result = try await fetchLearningProjectDetail(projectID: "project-1")

        #expect(result.nextSet == inProgressSet)
    }

    @Test
    func `모두 완료했으면 다음 세트가 없다`() async throws {
        let detail = makeDetail(sets: [
            LearningProjectSetProgress(setID: "set-1", label: "Set 1", title: "title", problemCount: 5, completedCount: 5)
        ])
        let fetchLearningProjectDetail = FetchLearningProjectDetail(
            repository: FetchLearningProjectDetailRepository(behavior: .succeed(detail))
        )

        let result = try await fetchLearningProjectDetail(projectID: "project-1")

        #expect(result.nextSet == nil)
    }

    @Test
    func `미존재 오류를 그대로 전파한다`() async throws {
        let fetchLearningProjectDetail = FetchLearningProjectDetail(
            repository: FetchLearningProjectDetailRepository(behavior: .fail(.notFound))
        )

        await #expect(throws: LearningProjectError.notFound) {
            try await fetchLearningProjectDetail(projectID: "project-1")
        }
    }
}

extension FetchLearningProjectDetailTests {
    private func makeDetail(sets: [LearningProjectSetProgress]) -> LearningProjectDetail {
        LearningProjectDetail(
            projectID: "project-1",
            repositoryURL: "https://github.com/owner/repo",
            repositoryName: "repo",
            repositoryImageURL: nil,
            starCount: 0,
            techStack: [],
            overallProgressPercent: 0,
            nextQuestionID: nil,
            sets: sets,
        )
    }
}

// MARK: - FetchLearningProjectDetailRepository

private actor FetchLearningProjectDetailRepository: LearningProjectRepository {

    // MARK: Lifecycle

    init(behavior: Behavior) {
        self.behavior = behavior
    }

    // MARK: Internal

    enum Behavior: Sendable {
        case succeed(LearningProjectDetail)
        case fail(LearningProjectError)
    }

    func register(
        githubRepoURL _: String,
        quizLevel _: QuizLevel,
    ) async throws -> LearningProjectRegistration {
        throw LearningProjectError.unexpected
    }

    func fetchProjects(
        page _: Int,
        size _: Int,
    ) async throws -> LearningProjectPage {
        throw LearningProjectError.unexpected
    }

    func fetchProjectDetail(projectID _: String) async throws -> LearningProjectDetail {
        switch behavior {
        case .succeed(let detail):
            return detail

        case .fail(let error):
            throw error
        }
    }

    func deleteProject(projectID _: String) async throws {
        throw LearningProjectError.unexpected
    }

    // MARK: Private

    private let behavior: Behavior

}
