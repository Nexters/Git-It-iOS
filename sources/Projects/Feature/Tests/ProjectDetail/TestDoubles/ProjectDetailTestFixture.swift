import DomainLearningProject

enum ProjectDetailTestFixture {

    // MARK: Internal

    static let projectID = "project-1"
    static let repositoryURL = "https://github.com/owner/repo"

    /// 완료된 세트와 진행 중 세트, 시작 전 세트가 섞인 상세입니다.
    static let mixedProgressDetail = detail(sets: [
        setProgress(index: 0, problemCount: 5, completedCount: 5),
        setProgress(index: 1, problemCount: 4, completedCount: 2),
        setProgress(index: 2, problemCount: 3, completedCount: 0),
    ])

    /// 모든 세트가 완료된 상세입니다.
    static let completedDetail = detail(sets: [
        setProgress(index: 0, problemCount: 5, completedCount: 5),
        setProgress(index: 1, problemCount: 4, completedCount: 4),
    ])

    /// 세트가 하나도 없는 상세입니다.
    static let emptyDetail = detail(sets: [])

    static let savedQuestionCollection = BookmarkedQuestionCollection(
        totalCount: 2,
        availableProjects: [projectID],
        bookmarks: [
            BookmarkedQuestion(
                projectID: projectID,
                setID: "set-0",
                questionID: "question-0",
                prompt: "저장한 문제 0",
            ),
            BookmarkedQuestion(
                projectID: projectID,
                setID: "set-1",
                questionID: "question-1",
                prompt: "저장한 문제 1",
            ),
        ],
    )

    static let otherProjectQuestionCollection = BookmarkedQuestionCollection(
        totalCount: 1,
        availableProjects: ["project-2"],
        bookmarks: [
            BookmarkedQuestion(
                projectID: "project-2",
                setID: "set-9",
                questionID: "question-9",
                prompt: "다른 프로젝트의 저장한 문제",
            )
        ],
    )

    static let emptyQuestionCollection = BookmarkedQuestionCollection(
        totalCount: 0,
        availableProjects: [],
        bookmarks: [],
    )

    static func setProgress(
        index: Int,
        problemCount: Int,
        completedCount: Int,
    ) -> LearningProjectSetProgress {
        LearningProjectSetProgress(
            setID: "set-\(index)",
            label: "CHAPTER \(index + 1)",
            title: "학습 세트 \(index)",
            problemCount: problemCount,
            completedCount: completedCount,
        )
    }

    static func detail(sets: [LearningProjectSetProgress]) -> LearningProjectDetail {
        LearningProjectDetail(
            projectID: projectID,
            repositoryURL: repositoryURL,
            repositoryName: "owner/repo",
            repositoryImageURL: nil,
            starCount: 42,
            techStack: ["Swift", "SwiftUI"],
            overallProgressPercent: progressPercent(sets: sets),
            nextQuestionID: nil,
            sets: sets,
        )
    }

    // MARK: Private

    private static func progressPercent(sets: [LearningProjectSetProgress]) -> Int {
        let total = sets.reduce(0) { $0 + $1.problemCount }
        guard total > 0 else { return 0 }
        let completed = sets.reduce(0) { $0 + $1.completedCount }
        return completed * 100 / total
    }

}
