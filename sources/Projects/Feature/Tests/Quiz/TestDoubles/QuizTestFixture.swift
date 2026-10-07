import DomainLearningProject

enum QuizTestFixture {

    // MARK: Internal

    static let projectID = "project-1"
    static let setID = "set-1"
    static let setLabel = "CHAPTER 1"

    static let unansweredSet = set(answeredCount: 0)
    static let partiallyAnsweredSet = set(answeredCount: 2)
    static let fullyAnsweredSet = set(answeredCount: 3)

    static let essayOnlySet = LearningSet(
        setID: setID,
        title: "서술형 전용 세트",
        description: "서술형만 담긴 세트입니다.",
        questions: [
            essayQuestion(index: 0, myAnswer: nil),
            essayQuestion(index: 1, myAnswer: nil),
        ],
    )

    static let emptySet = LearningSet(
        setID: setID,
        title: "빈 세트",
        description: "문제가 없는 세트입니다.",
        questions: [],
    )

    static let questionWithoutSources = Question(
        questionID: "question-no-source",
        prompt: "출처가 없는 문제",
        format: .multipleChoice,
        choices: choices,
        sources: [],
        myAnswer: nil,
    )

    static let questionWithManySources = Question(
        questionID: "question-many-sources",
        prompt: "출처가 여럿인 문제",
        format: .multipleChoice,
        choices: choices,
        sources: [fileSource, referenceSource],
        myAnswer: nil,
    )

    static let fileSource = QuestionSource(
        filePath: "Sources/App/AppDelegate.swift",
        startLine: 10,
        endLine: 24,
        symbol: "application(_:didFinishLaunchingWithOptions:)",
        summary: "앱 시작 지점입니다.",
        referenceURL: nil,
    )

    static let referenceSource = QuestionSource(
        filePath: nil,
        startLine: nil,
        endLine: nil,
        symbol: nil,
        summary: "공식 문서",
        referenceURL: "https://developer.apple.com/documentation/swiftui",
    )

    static let correctChoiceResult = ChoiceAnswerResult(
        correct: true,
        answerIndex: 1,
        explanation: "두 번째 선택지가 정답입니다.",
    )

    static let incorrectChoiceResult = ChoiceAnswerResult(
        correct: false,
        answerIndex: 2,
        explanation: "세 번째 선택지가 정답입니다.",
    )

    static let essayResult = EssayAnswerResult(
        explanation: "AI가 작성한 모범 답안입니다.",
        rubric: Rubric(criteria: ["핵심 개념", "예시"]),
    )

    static let bookmarkCollection = BookmarkedQuestionCollection(
        totalCount: 1,
        availableProjects: [BookmarkedProject(id: projectID, name: "owner/repo")],
        bookmarks: [bookmarkedQuestion(index: 0)],
    )

    static func choiceQuestion(
        index: Int,
        myAnswer: SubmittedAnswer?,
    ) -> Question {
        Question(
            questionID: "question-\(index)",
            prompt: "객관식 문제 \(index)",
            format: .multipleChoice,
            choices: choices,
            sources: [fileSource],
            myAnswer: myAnswer,
        )
    }

    static func essayQuestion(
        index: Int,
        myAnswer: SubmittedAnswer?,
    ) -> Question {
        Question(
            questionID: "question-\(index)",
            prompt: "서술형 문제 \(index)",
            format: .essay,
            choices: nil,
            sources: [fileSource, referenceSource],
            myAnswer: myAnswer,
        )
    }

    static func bookmarkedQuestion(
        index: Int,
        projectID: String = QuizTestFixture.projectID,
        setID: String = QuizTestFixture.setID,
    ) -> BookmarkedQuestion {
        BookmarkedQuestion(
            projectID: projectID,
            setID: setID,
            questionID: "question-\(index)",
            prompt: "저장한 문제 \(index)",
        )
    }

    static func set(answeredCount: Int) -> LearningSet {
        LearningSet(
            setID: setID,
            title: "학습 세트",
            description: "세트 설명입니다.",
            questions: [
                choiceQuestion(
                    index: 0,
                    myAnswer: answeredCount > 0
                        ? SubmittedAnswer(selectedIndex: 1, text: nil, correct: true)
                        : nil,
                ),
                choiceQuestion(
                    index: 1,
                    myAnswer: answeredCount > 1
                        ? SubmittedAnswer(selectedIndex: 0, text: nil, correct: false)
                        : nil,
                ),
                essayQuestion(
                    index: 2,
                    myAnswer: answeredCount > 2
                        ? SubmittedAnswer(selectedIndex: nil, text: "제출한 답안", correct: nil)
                        : nil,
                ),
            ],
        )
    }

    // MARK: Private

    private static let choices = ["첫 번째", "두 번째", "세 번째", "네 번째"]

}
