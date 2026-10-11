import DomainUseCaseInterface

enum QuizTestFixture {

    // MARK: Internal

    static let projectID = "project-1"
    static let setID = "set-1"
    static let setLabel = "CHAPTER 1"

    static let unansweredSet = set(answeredCount: 0)
    static let partiallyAnsweredSet = set(answeredCount: 2)
    static let fullyAnsweredSet = set(answeredCount: 3)

    static let essayOnlySet = QuizSet(
        id: setID,
        title: "서술형 전용 세트",
        description: "서술형만 담긴 세트입니다.",
        quizzes: [
            essayQuiz(
                index: 0,
                submitted: nil,
            ),
            essayQuiz(
                index: 1,
                submitted: nil,
            ),
        ],
    )

    static let emptySet = QuizSet(
        id: setID,
        title: "빈 세트",
        description: "문제가 없는 세트입니다.",
        quizzes: [],
    )

    static let quizWithoutSources = Quiz(
        id: "quiz-no-source",
        prompt: "출처가 없는 문제",
        content: .choice(
            options: choices,
            submitted: nil,
        ),
        sources: [],
    )

    static let quizWithManySources = Quiz(
        id: "quiz-many-sources",
        prompt: "출처가 여럿인 문제",
        content: .choice(
            options: choices,
            submitted: nil,
        ),
        sources: [fileSource, referenceSource],
    )

    static let fileSource = QuizSource(
        filePath: "Sources/App/AppDelegate.swift",
        startLine: 10,
        endLine: 24,
        symbol: "application(_:didFinishLaunchingWithOptions:)",
        summary: "앱 시작 지점입니다.",
        referenceURL: nil,
    )

    static let referenceSource = QuizSource(
        filePath: nil,
        startLine: nil,
        endLine: nil,
        symbol: nil,
        summary: "공식 문서",
        referenceURL: "https://developer.apple.com/documentation/swiftui",
    )

    static let correctChoiceGrading = ChoiceGrading(
        isCorrect: true,
        correctIndex: 1,
        explanation: "두 번째 선택지가 정답입니다.",
    )

    static let incorrectChoiceGrading = ChoiceGrading(
        isCorrect: false,
        correctIndex: 2,
        explanation: "세 번째 선택지가 정답입니다.",
    )

    static let essayGrading = EssayGrading(
        explanation: "AI가 작성한 모범 답안입니다.",
        rubric: ["핵심 개념", "예시"],
    )

    static let bookmarkList = QuizBookmarkList(
        totalCount: 1,
        projects: [QuizBookmarkProject(
            id: projectID,
            name: "owner/repo",
        )],
        bookmarks: [bookmark(index: 0)],
    )

    static func choiceQuiz(
        index: Int,
        submitted: ChoiceSubmission?,
    ) -> Quiz {
        Quiz(
            id: "quiz-\(index)",
            prompt: "객관식 문제 \(index)",
            content: .choice(
                options: choices,
                submitted: submitted,
            ),
            sources: [fileSource],
        )
    }

    static func essayQuiz(
        index: Int,
        submitted: EssaySubmission?,
    ) -> Quiz {
        Quiz(
            id: "quiz-\(index)",
            prompt: "서술형 문제 \(index)",
            content: .essay(submitted: submitted),
            sources: [fileSource, referenceSource],
        )
    }

    static func bookmark(
        index: Int,
        projectID: ProjectID = QuizTestFixture.projectID,
        setID: QuizSetID = QuizTestFixture.setID,
    ) -> QuizBookmark {
        QuizBookmark(
            projectID: projectID,
            projectName: "owner/repo",
            setID: setID,
            setLabel: setLabel,
            problemNumber: index + 1,
            quizID: "quiz-\(index)",
            prompt: "저장한 문제 \(index)",
        )
    }

    static func set(answeredCount: Int) -> QuizSet {
        QuizSet(
            id: setID,
            title: "학습 세트",
            description: "세트 설명입니다.",
            quizzes: [
                choiceQuiz(
                    index: 0,
                    submitted: answeredCount > 0
                        ? ChoiceSubmission(
                            selectedIndex: 1,
                            isCorrect: true,
                        )
                        : nil,
                ),
                choiceQuiz(
                    index: 1,
                    submitted: answeredCount > 1
                        ? ChoiceSubmission(
                            selectedIndex: 0,
                            isCorrect: false,
                        )
                        : nil,
                ),
                essayQuiz(
                    index: 2,
                    submitted: answeredCount > 2
                        ? EssaySubmission(text: "제출한 답안")
                        : nil,
                ),
            ],
        )
    }

    // MARK: Private

    private static let choices = ["첫 번째", "두 번째", "세 번째", "네 번째"]

}
