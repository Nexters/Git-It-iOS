import Testing

@testable import DomainLearningProject

// MARK: - CreateLearningProjectTests

@Suite("CreateLearningProject")
struct CreateLearningProjectTests {
    @Test
    func `신규 등록 결과를 그대로 반환한다`() async throws {
        let registration = LearningProjectRegistration(
            projectId: "project-1",
            status: .ready,
            quizLevel: .l1,
        )
        let createLearningProject = makeCreateLearningProject(behavior: .succeed(registration))

        let result = try await createLearningProject(githubRepoUrl: "https://github.com/owner/repo", quizLevel: .l1)

        #expect(result == registration)
    }

    @Test
    func `재등록 응답도 신규 등록과 구분 없이 그대로 반환한다`() async throws {
        let existingRegistration = LearningProjectRegistration(
            projectId: "existing-project",
            status: .analyzed,
            quizLevel: .l2,
        )
        let createLearningProject = makeCreateLearningProject(behavior: .succeed(existingRegistration))

        let result = try await createLearningProject(githubRepoUrl: "https://github.com/owner/repo", quizLevel: .l2)

        #expect(result == existingRegistration)
    }

    @Test
    func `삭제 후 복원 응답도 그대로 반환한다`() async throws {
        let restoredRegistration = LearningProjectRegistration(
            projectId: "restored-project",
            status: .completed,
            quizLevel: .l3,
        )
        let createLearningProject = makeCreateLearningProject(behavior: .succeed(restoredRegistration))

        let result = try await createLearningProject(githubRepoUrl: "https://github.com/owner/repo", quizLevel: .l3)

        #expect(result == restoredRegistration)
    }

    @Test
    func `잘못된 요청 오류를 그대로 전파한다`() async throws {
        let createLearningProject = makeCreateLearningProject(behavior: .fail(.invalidRequest))

        await #expect(throws: LearningProjectError.invalidRequest) {
            try await createLearningProject(githubRepoUrl: "https://github.com/owner/repo", quizLevel: .l1)
        }
    }

    @Test
    func `미인증 오류를 그대로 전파한다`() async throws {
        let createLearningProject = makeCreateLearningProject(behavior: .fail(.unauthorized))

        await #expect(throws: LearningProjectError.unauthorized) {
            try await createLearningProject(githubRepoUrl: "https://github.com/owner/repo", quizLevel: .l1)
        }
    }
}

extension CreateLearningProjectTests {
    private func makeCreateLearningProject(
        behavior: CreateLearningProjectRepository.Behavior
    ) -> CreateLearningProject {
        CreateLearningProject(repository: CreateLearningProjectRepository(behavior: behavior))
    }
}

// MARK: - CreateLearningProjectRepository

private actor CreateLearningProjectRepository: LearningProjectRepository {

    // MARK: Lifecycle

    init(behavior: Behavior) {
        self.behavior = behavior
    }

    // MARK: Internal

    enum Behavior: Sendable {
        case succeed(LearningProjectRegistration)
        case fail(LearningProjectError)
    }

    func register(
        githubRepoUrl _: String,
        quizLevel _: QuizLevel,
    ) async throws -> LearningProjectRegistration {
        switch behavior {
        case .succeed(let registration):
            return registration

        case .fail(let error):
            throw error
        }
    }

    func fetchProjects(
        page _: Int,
        size _: Int,
    ) async throws -> LearningProjectPage {
        throw LearningProjectError.unexpected
    }

    func fetchProjectDetail(projectId _: String) async throws -> LearningProjectDetail {
        throw LearningProjectError.unexpected
    }

    func deleteProject(projectId _: String) async throws {
        throw LearningProjectError.unexpected
    }

    // MARK: Private

    private let behavior: Behavior

}
