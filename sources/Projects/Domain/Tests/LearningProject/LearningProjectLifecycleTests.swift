import Testing

@testable import DomainLearningProject

// MARK: - LearningProjectLifecycleTests

@Suite("학습 프로젝트 생명주기 조합")
struct LearningProjectLifecycleTests {
    @Test
    func `조회한 외부 Repository를 그대로 등록에 전달한다`() async throws {
        let externalRepository = ExternalRepository(
            canonicalURL: "https://github.com/owner/repo",
            ownerName: "owner",
            repositoryName: "repo",
            imageURL: nil,
            starCount: 7,
            techStack: ["Swift"],
        )
        let registration = ProjectRegistrationReceipt(
            projectID: "project-1",
            requestStatus: "READY",
            quizLevel: .l1,
        )
        let fetchExternalRepository = FetchExternalRepository(
            lookup: LifecycleExternalRepositoryLookup(repository: externalRepository)
        )
        let createLearningProject = CreateLearningProject(
            repository: LifecycleLearningProjectRepository(registration: registration)
        )

        let fetchedRepository = try await fetchExternalRepository(url: "https://github.com/owner/repo")
        let result = try await createLearningProject(
            githubRepoURL: fetchedRepository.canonicalURL,
            quizLevel: .l1,
        )

        #expect(result.projectID == registration.projectID)
        #expect(result.requestStatus == registration.requestStatus)
    }

    @Test
    func `삭제 후 같은 Repository로 상세 조회하면 미존재로 처리된다`() async throws {
        let repository = LifecycleLearningProjectRepository(registration: ProjectRegistrationReceipt(
            projectID: "project-1",
            requestStatus: "READY",
            quizLevel: .l1,
        ))
        let deleteLearningProject = DeleteLearningProject(repository: repository)
        let fetchLearningProjectDetail = FetchLearningProjectDetail(repository: repository)

        try await deleteLearningProject(projectID: "project-1")

        await #expect(throws: LearningProjectError.notFound) {
            try await fetchLearningProjectDetail(projectID: "project-1")
        }
    }
}

// MARK: - LifecycleExternalRepositoryLookup

private actor LifecycleExternalRepositoryLookup: ExternalRepositoryLookup {

    // MARK: Lifecycle

    init(repository: ExternalRepository) {
        self.repository = repository
    }

    // MARK: Internal

    func repository(
        owner _: String,
        name _: String,
    ) async throws -> ExternalRepository {
        repository
    }

    // MARK: Private

    private let repository: ExternalRepository

}

// MARK: - LifecycleLearningProjectRepository

private actor LifecycleLearningProjectRepository: LearningProjectRepository {

    // MARK: Lifecycle

    init(registration: ProjectRegistrationReceipt) {
        self.registration = registration
    }

    // MARK: Internal

    func register(
        githubRepoURL _: String,
        quizLevel _: QuizLevel,
    ) async throws -> ProjectRegistrationReceipt {
        registration
    }

    func fetchProjects(
        page _: Int,
        size _: Int,
    ) async throws -> LearningProjectPage {
        LearningProjectPage(items: [], hasNext: false)
    }

    func fetchProjectDetail(projectID _: String) async throws -> LearningProjectDetail {
        guard !deleted
        else {
            throw LearningProjectError.notFound
        }

        return LearningProjectDetail(
            projectID: registration.projectID,
            repositoryURL: "https://github.com/owner/repo",
            repositoryName: "repo",
            repositoryImageURL: nil,
            starCount: 0,
            techStack: [],
            overallProgressPercent: 0,
            nextQuestionID: nil,
            sets: [],
        )
    }

    func deleteProject(projectID _: String) async throws {
        deleted = true
    }

    // MARK: Private

    private let registration: ProjectRegistrationReceipt
    private var deleted = false

}
