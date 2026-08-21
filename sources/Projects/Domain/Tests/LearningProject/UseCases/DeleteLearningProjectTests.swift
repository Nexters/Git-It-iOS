import Testing

@testable import DomainLearningProject

// MARK: - DeleteLearningProjectTests

@Suite("DeleteLearningProject")
struct DeleteLearningProjectTests {
    @Test
    func `성공하면 오류 없이 완료한다`() async throws {
        let deleteLearningProject = DeleteLearningProject(
            repository: DeleteLearningProjectRepository(behavior: .succeed)
        )

        try await deleteLearningProject(projectID: "project-1")
    }

    @Test
    func `미존재 오류를 그대로 전파한다`() async throws {
        let deleteLearningProject = DeleteLearningProject(
            repository: DeleteLearningProjectRepository(behavior: .fail(.notFound))
        )

        await #expect(throws: LearningProjectError.notFound) {
            try await deleteLearningProject(projectID: "project-1")
        }
    }
}

// MARK: - DeleteLearningProjectRepository

private actor DeleteLearningProjectRepository: LearningProjectRepository {

    // MARK: Lifecycle

    init(behavior: Behavior) {
        self.behavior = behavior
    }

    // MARK: Internal

    enum Behavior: Sendable {
        case succeed
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
        throw LearningProjectError.unexpected
    }

    func fetchProjectDetail(projectID _: String) async throws -> LearningProjectDetail {
        throw LearningProjectError.unexpected
    }

    func deleteProject(projectID _: String) async throws {
        switch behavior {
        case .succeed:
            return

        case .fail(let error):
            throw error
        }
    }

    // MARK: Private

    private let behavior: Behavior

}
