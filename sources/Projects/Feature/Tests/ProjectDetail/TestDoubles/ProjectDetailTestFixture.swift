import DomainUseCaseInterface

enum ProjectDetailTestFixture {

    // MARK: Internal

    static let projectID = "project-1"
    static let repositoryURL = "https://github.com/owner/repo"

    static let mixedProgressDetail = detail(sets: [
        setProgress(
            index: 0,
            quizCount: 5,
            completedCount: 5,
        ),
        setProgress(
            index: 1,
            quizCount: 4,
            completedCount: 2,
        ),
        setProgress(
            index: 2,
            quizCount: 3,
            completedCount: 0,
        ),
    ])

    static let completedDetail = detail(sets: [
        setProgress(
            index: 0,
            quizCount: 5,
            completedCount: 5,
        ),
        setProgress(
            index: 1,
            quizCount: 4,
            completedCount: 4,
        ),
    ])

    static let emptyDetail = detail(sets: [])

    static let savedQuizList = QuizBookmarkList(
        totalCount: 2,
        projects: [QuizBookmarkProject(
            id: projectID,
            name: "owner/repo",
        )],
        bookmarks: [
            QuizBookmark(
                projectID: projectID,
                projectName: "owner/repo",
                setID: "set-0",
                setLabel: "CHAPTER 1",
                problemNumber: 1,
                quizID: "quiz-0",
                prompt: "저장한 문제 0",
            ),
            QuizBookmark(
                projectID: projectID,
                projectName: "owner/repo",
                setID: "set-1",
                setLabel: "CHAPTER 2",
                problemNumber: 2,
                quizID: "quiz-1",
                prompt: "저장한 문제 1",
            ),
        ],
    )

    static let otherProjectQuizList = QuizBookmarkList(
        totalCount: 1,
        projects: [QuizBookmarkProject(
            id: "project-2",
            name: "다른 프로젝트",
        )],
        bookmarks: [
            QuizBookmark(
                projectID: "project-2",
                projectName: "다른 프로젝트",
                setID: "set-9",
                setLabel: "CHAPTER 10",
                problemNumber: 1,
                quizID: "quiz-9",
                prompt: "다른 프로젝트의 저장한 문제",
            )
        ],
    )

    static let emptyQuizList = QuizBookmarkList(
        totalCount: 0,
        projects: [],
        bookmarks: [],
    )

    static func setProgress(
        index: Int,
        quizCount: Int,
        completedCount: Int,
    ) -> ProjectSetProgress {
        ProjectSetProgress(
            setID: "set-\(index)",
            label: "CHAPTER \(index + 1)",
            title: "학습 세트 \(index)",
            quizCount: quizCount,
            completedCount: completedCount,
        )
    }

    static func detail(sets: [ProjectSetProgress]) -> ProjectDetail {
        ProjectDetail(
            id: projectID,
            repository: ProjectRepositoryInfo(
                url: repositoryURL,
                name: "owner/repo",
                imageURL: nil,
                starCount: 42,
                techStack: ["Swift", "SwiftUI"],
            ),
            progressPercent: progressPercent(sets: sets),
            sets: sets,
            next: nextQuiz(sets: sets),
        )
    }

    // MARK: Private

    private static func progressPercent(sets: [ProjectSetProgress]) -> Int {
        let total = sets.reduce(0) { $0 + $1.quizCount }
        guard total > 0 else { return 0 }
        let completed = sets.reduce(0) { $0 + $1.completedCount }
        return completed * 100 / total
    }

    private static func nextQuiz(sets: [ProjectSetProgress]) -> ProjectNextQuiz? {
        let target = sets.first { $0.completedCount < $0.quizCount } ?? sets.first
        guard let target else { return nil }
        return ProjectNextQuiz(
            setID: target.setID,
            quizID: nil,
        )
    }

}
