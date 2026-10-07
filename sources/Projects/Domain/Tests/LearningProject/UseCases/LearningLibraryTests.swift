import Testing

@testable import DomainLearningProject

// MARK: - LearningLibraryTests

@Suite("LearningLibrary")
struct LearningLibraryTests {

    // MARK: Internal

    @Test
    func `진행 중 세트가 있으면 다음 세트가 일치한다`() async throws {
        let inProgressSet = LearningProjectSetProgress(
            setID: "set-2",
            label: "Set 2",
            title: "title",
            problemCount: 5,
            completedCount: 1,
        )
        let detail = Self.makeDetail(sets: [
            LearningProjectSetProgress(setID: "set-1", label: "Set 1", title: "title", problemCount: 5, completedCount: 5),
            inProgressSet,
        ])
        let library = Self.makeLibrary(projectBehavior: .succeed(detail))

        let result = try await library.project(id: "project-1")

        #expect(result.nextSet == inProgressSet)
    }

    @Test
    func `모두 완료했으면 replay를 위해 첫 세트로 되돌아간다`() async throws {
        let firstSet = LearningProjectSetProgress(
            setID: "set-1",
            label: "Set 1",
            title: "title",
            problemCount: 5,
            completedCount: 5,
        )
        let library = Self.makeLibrary(projectBehavior: .succeed(Self.makeDetail(sets: [firstSet])))

        let result = try await library.project(id: "project-1")

        #expect(result.nextSet == firstSet)
    }

    @Test
    func `세트가 비어 있으면 다음 세트가 없다`() async throws {
        let library = Self.makeLibrary(projectBehavior: .succeed(Self.makeDetail(sets: [])))

        let result = try await library.project(id: "project-1")

        #expect(result.nextSet == nil)
    }

    @Test
    func `프로젝트 미존재 오류를 그대로 전파한다`() async throws {
        let library = Self.makeLibrary(projectBehavior: .fail(.notFound))

        await #expect(throws: LearningProjectError.notFound) {
            _ = try await library.project(id: "project-1")
        }
    }

    @Test
    func `프로젝트 삭제는 성공하면 오류 없이 완료한다`() async throws {
        let repository = LibraryProjectRepository(behavior: .succeed(Self.makeDetail(sets: [])))
        let library = LearningLibrary(
            projectRepository: repository,
            learningSetRepository: LibraryLearningSetRepository(behavior: .fail(.unexpected)),
            bookmarkRepository: LibraryBookmarkRepository(collection: Self.emptyCollection),
        )

        try await library.deleteProject(id: "project-1")

        #expect(await repository.deletedProjectID == "project-1")
    }

    @Test
    func `프로젝트 삭제의 미존재 오류를 그대로 전파한다`() async throws {
        let library = Self.makeLibrary(projectBehavior: .fail(.notFound))

        await #expect(throws: LearningProjectError.notFound) {
            try await library.deleteProject(id: "project-1")
        }
    }

    @Test
    func `서버 순서를 유지한 채 모든 문제 형식을 전달한다`() async throws {
        let questions = [
            Question(
                questionID: "q1",
                prompt: "prompt-1",
                format: .multipleChoice,
                choices: ["a", "b"],
                sources: [],
                myAnswer: nil,
            ),
            Question(
                questionID: "q2",
                prompt: "prompt-2",
                format: .essay,
                choices: nil,
                sources: [],
                myAnswer: nil,
            ),
        ]
        let set = LearningSet(setID: "set-1", title: "title", description: "description", questions: questions)
        let library = Self.makeLibrary(setBehavior: .succeed(set))

        let result = try await library.learningSet(projectID: "project-1", setID: "set-1")

        #expect(result.questions.map(\.questionID) == ["q1", "q2"])
        #expect(result.questions[0].format == .multipleChoice)
        #expect(result.questions[1].format == .essay)
    }

    @Test
    func `제출 전에는 myAnswer가 노출되지 않는다`() async throws {
        let question = Question(
            questionID: "q1",
            prompt: "prompt",
            format: .multipleChoice,
            choices: ["a"],
            sources: [],
            myAnswer: nil,
        )
        let set = LearningSet(setID: "set-1", title: "title", description: "description", questions: [question])
        let library = Self.makeLibrary(setBehavior: .succeed(set))

        let result = try await library.learningSet(projectID: "project-1", setID: "set-1")

        #expect(result.questions[0].myAnswer == nil)
    }

    @Test
    func `세트 미존재 오류를 그대로 전파한다`() async throws {
        let library = Self.makeLibrary(setBehavior: .fail(.learningSetUnavailable))

        await #expect(throws: LearningProjectError.learningSetUnavailable) {
            _ = try await library.learningSet(projectID: "project-1", setID: "set-1")
        }
    }

    @Test
    func `필터와 무관하게 availableProjects는 전체 목록을 유지한다`() async throws {
        let collection = BookmarkedQuestionCollection(
            totalCount: 3,
            availableProjects: [
                BookmarkedProject(id: "project-1", name: "repo-1"),
                BookmarkedProject(id: "project-2", name: "repo-2"),
            ],
            bookmarks: [
                BookmarkedQuestion(projectID: "project-1", setID: "set-1", questionID: "q1", prompt: "p1")
            ],
        )
        let library = Self.makeLibrary(bookmarkCollection: collection)

        let result = try await library.bookmarkedQuestions(projectID: "project-1")

        #expect(result.availableProjects == [
            BookmarkedProject(id: "project-1", name: "repo-1"),
            BookmarkedProject(id: "project-2", name: "repo-2"),
        ])
    }

    @Test
    func `route 식별자를 완전하게 보존한다`() async throws {
        let bookmark = BookmarkedQuestion(projectID: "project-1", setID: "set-1", questionID: "q1", prompt: "p1")
        let collection = BookmarkedQuestionCollection(
            totalCount: 1,
            availableProjects: [BookmarkedProject(id: "project-1", name: "repo-1")],
            bookmarks: [bookmark],
        )
        let library = Self.makeLibrary(bookmarkCollection: collection)

        let result = try await library.bookmarkedQuestions(projectID: nil)

        #expect(result.bookmarks.first?.projectID == "project-1")
        #expect(result.bookmarks.first?.setID == "set-1")
        #expect(result.bookmarks.first?.questionID == "q1")
    }

    // MARK: Private

    private static let emptyCollection = BookmarkedQuestionCollection(
        totalCount: 0,
        availableProjects: [],
        bookmarks: [],
    )

    private static func makeDetail(sets: [LearningProjectSetProgress]) -> LearningProjectDetail {
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

    private static func makeLibrary(
        projectBehavior: LibraryProjectRepository.Behavior = .fail(.unexpected),
        setBehavior: LibraryLearningSetRepository.Behavior = .fail(.unexpected),
        bookmarkCollection: BookmarkedQuestionCollection = emptyCollection,
    ) -> LearningLibrary {
        LearningLibrary(
            projectRepository: LibraryProjectRepository(behavior: projectBehavior),
            learningSetRepository: LibraryLearningSetRepository(behavior: setBehavior),
            bookmarkRepository: LibraryBookmarkRepository(collection: bookmarkCollection),
        )
    }

}

// MARK: - LibraryProjectRepository

private actor LibraryProjectRepository: LearningProjectRepository {

    // MARK: Lifecycle

    init(behavior: Behavior) {
        self.behavior = behavior
    }

    // MARK: Internal

    enum Behavior: Sendable {
        case succeed(LearningProjectDetail)
        case fail(LearningProjectError)
    }

    private(set) var deletedProjectID: String?

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
        switch behavior {
        case .succeed(let detail):
            return detail

        case .fail(let error):
            throw error
        }
    }

    func deleteProject(projectID: String) async throws {
        switch behavior {
        case .succeed:
            deletedProjectID = projectID

        case .fail(let error):
            throw error
        }
    }

    // MARK: Private

    private let behavior: Behavior

}

// MARK: - LibraryLearningSetRepository

private struct LibraryLearningSetRepository: LearningSetRepository {
    enum Behavior: Sendable {
        case succeed(LearningSet)
        case fail(LearningProjectError)
    }

    let behavior: Behavior

    func fetchSet(
        projectID _: String,
        setID _: String,
    ) async throws -> LearningSet {
        switch behavior {
        case .succeed(let set):
            return set

        case .fail(let error):
            throw error
        }
    }
}

// MARK: - LibraryBookmarkRepository

private struct LibraryBookmarkRepository: BookmarkRepository {
    let collection: BookmarkedQuestionCollection

    func setBookmark(
        projectID _: String,
        questionID _: String,
        bookmarked: Bool,
    ) async throws -> BookmarkState {
        BookmarkState(bookmarked: bookmarked)
    }

    func fetchBookmarkedQuestions(projectID _: String?) async throws -> BookmarkedQuestionCollection {
        collection
    }
}
