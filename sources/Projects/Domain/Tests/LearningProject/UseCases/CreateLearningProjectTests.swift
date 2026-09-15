import Testing

@testable import DomainLearningProject

// MARK: - CreateLearningProjectTests

@Suite("CreateLearningProject")
struct CreateLearningProjectTests {
    @Test
    func `신규 등록 결과를 그대로 반환한다`() async throws {
        let registration = ProjectRegistrationReceipt(
            projectID: "project-1",
            requestStatus: "READY",
            quizLevel: .l1,
        )
        let createLearningProject = makeCreateLearningProject(behavior: .succeed(registration))

        let result = try await createLearningProject(githubRepoURL: "https://github.com/owner/repo", quizLevel: .l1)

        #expect(result == registration)
    }

    @Test
    func `재등록 응답도 신규 등록과 구분 없이 그대로 반환한다`() async throws {
        let existingRegistration = ProjectRegistrationReceipt(
            projectID: "existing-project",
            requestStatus: "ANALYZED",
            quizLevel: .l2,
        )
        let createLearningProject = makeCreateLearningProject(behavior: .succeed(existingRegistration))

        let result = try await createLearningProject(githubRepoURL: "https://github.com/owner/repo", quizLevel: .l2)

        #expect(result == existingRegistration)
    }

    @Test
    func `삭제 후 복원 응답도 그대로 반환한다`() async throws {
        let restoredRegistration = ProjectRegistrationReceipt(
            projectID: "restored-project",
            requestStatus: "COMPLETED",
            quizLevel: .l3,
        )
        let createLearningProject = makeCreateLearningProject(behavior: .succeed(restoredRegistration))

        let result = try await createLearningProject(githubRepoURL: "https://github.com/owner/repo", quizLevel: .l3)

        #expect(result == restoredRegistration)
    }

    @Test
    func `잘못된 요청 오류를 그대로 전파한다`() async throws {
        let createLearningProject = makeCreateLearningProject(behavior: .fail(.invalidRequest))

        await #expect(throws: LearningProjectError.invalidRequest) {
            try await createLearningProject(githubRepoURL: "https://github.com/owner/repo", quizLevel: .l1)
        }
    }

    @Test
    func `미인증 오류를 그대로 전파한다`() async throws {
        let createLearningProject = makeCreateLearningProject(behavior: .fail(.unauthorized))

        await #expect(throws: LearningProjectError.unauthorized) {
            try await createLearningProject(githubRepoURL: "https://github.com/owner/repo", quizLevel: .l1)
        }
    }

    @Test
    func `동일 레포지토리에 대한 생성이 이미 진행 중이면 서버 요청 없이 중복 생성 오류를 던진다`() async throws {
        let registration = ProjectRegistrationReceipt(projectID: "project-1", requestStatus: "READY", quizLevel: .l1)
        let repository = CreateLearningProjectRepository(behavior: .succeed(registration))
        let trackGeneration = Self.makeTrackGeneration()
        let createLearningProject = CreateLearningProject(
            repository: repository,
            trackGeneration: trackGeneration,
        )

        _ = try await createLearningProject(githubRepoURL: "https://github.com/owner/repo", quizLevel: .l1)

        await #expect(throws: LearningProjectError.duplicateCreationInProgress) {
            try await createLearningProject(githubRepoURL: "https://github.com/owner/repo", quizLevel: .l1)
        }
        let registerCallCount = await repository.registerCallCount
        #expect(registerCallCount == 1)
    }

    @Test
    func `서로 다른 레포지토리는 동시에 생성 요청할 수 있다`() async throws {
        let registration = ProjectRegistrationReceipt(projectID: "project-1", requestStatus: "READY", quizLevel: .l1)
        let repository = CreateLearningProjectRepository(behavior: .succeed(registration))
        let trackGeneration = Self.makeTrackGeneration()
        let createLearningProject = CreateLearningProject(
            repository: repository,
            trackGeneration: trackGeneration,
        )

        _ = try await createLearningProject(githubRepoURL: "https://github.com/owner/repo-a", quizLevel: .l1)
        _ = try await createLearningProject(githubRepoURL: "https://github.com/owner/repo-b", quizLevel: .l1)

        let registerCallCount = await repository.registerCallCount
        #expect(registerCallCount == 2)
    }

    @Test
    func `서버 등록이 실패하면 생성 중 상태를 해제해 재시도를 허용한다`() async throws {
        let repository = CreateLearningProjectRepository(behavior: .fail(.temporarilyUnavailable))
        let trackGeneration = Self.makeTrackGeneration()
        let createLearningProject = CreateLearningProject(
            repository: repository,
            trackGeneration: trackGeneration,
        )

        await #expect(throws: LearningProjectError.temporarilyUnavailable) {
            try await createLearningProject(githubRepoURL: "https://github.com/owner/repo", quizLevel: .l1)
        }

        let stillCreating = await trackGeneration.current().isCreating(githubRepoURL: "https://github.com/owner/repo")
        #expect(stillCreating == false)
    }
}

extension CreateLearningProjectTests {
    static func makeTrackGeneration() -> TrackGeneration {
        TrackGeneration(
            stateRepository: StubGenerationStateRepository(),
            outcomeRepository: StubGenerationOutcomeRepository(),
        )
    }

    private func makeCreateLearningProject(
        behavior: CreateLearningProjectRepository.Behavior
    ) -> CreateLearningProject {
        CreateLearningProject(
            repository: CreateLearningProjectRepository(behavior: behavior),
            trackGeneration: Self.makeTrackGeneration(),
        )
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
        case succeed(ProjectRegistrationReceipt)
        case fail(LearningProjectError)
    }

    private(set) var registerCallCount = 0

    func register(
        githubRepoURL _: String,
        quizLevel _: QuizLevel,
    ) async throws -> ProjectRegistrationReceipt {
        registerCallCount += 1
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

    func fetchProjectDetail(projectID _: String) async throws -> LearningProjectDetail {
        throw LearningProjectError.unexpected
    }

    func deleteProject(projectID _: String) async throws {
        throw LearningProjectError.unexpected
    }

    // MARK: Private

    private let behavior: Behavior

}
