import ComposableArchitecture
import DomainLearningProject
import SwiftUI
import UIComponent

private let previewSources = [
    QuestionSource(
        filePath: "Sources/App/Composition/AppComposition.swift",
        startLine: 42,
        endLine: 60,
        symbol: "AppComposition",
        summary: "의존성을 조립하는 지점입니다.",
        referenceURL: nil,
    ),
    QuestionSource(
        filePath: nil,
        startLine: nil,
        endLine: nil,
        symbol: nil,
        summary: "공식 문서",
        referenceURL: "https://developer.apple.com/documentation/swiftui",
    ),
]

private let choiceQuestion = Question(
    questionID: "question-1",
    prompt: "Composition 패키지가 Domain에 의존해도 되는 이유는 무엇인가?",
    format: .multipleChoice,
    choices: [
        "Domain이 다른 패키지에 의존하지 않기 때문",
        "Composition이 앱 진입점이기 때문",
        "Domain이 UI를 포함하기 때문",
        "의존 방향에 제약이 없기 때문",
    ],
    sources: previewSources,
    myAnswer: nil,
)

private let essayQuestion = Question(
    questionID: "question-2",
    prompt: "생성자 주입이 Service Locator보다 나은 점을 설명하세요.",
    format: .essay,
    choices: nil,
    sources: previewSources,
    myAnswer: nil,
)

private func previewState(
    question: Question = choiceQuestion,
    questionNumber: Int? = 3,
    questionCount: Int? = 10,
    advanceActionTitle: String = "다음 문제",
    submission: QuestionSolvingFeature.Submission = .editing,
    draftChoiceIndex: Int? = nil,
    draftEssayText: String = "",
    isSourceSheetPresented: Bool = false,
) -> QuestionSolvingFeature.State {
    var state = QuestionSolvingFeature.State(
        projectID: "project-1",
        question: question,
        questionNumber: questionNumber,
        questionCount: questionCount,
        advanceActionTitle: advanceActionTitle,
    )
    state.submission = submission
    state.draftChoiceIndex = draftChoiceIndex
    state.draftEssayText = draftEssayText
    state.isSourceSheetPresented = isSourceSheetPresented
    return state
}

private func previewStore(_ state: QuestionSolvingFeature.State) -> StoreOf<QuestionSolvingFeature> {
    Store(initialState: state) { EmptyReducer() }
}

private let correctResult = ChoiceAnswerResult(
    correct: true,
    answerIndex: 0,
    explanation: "Domain은 다른 패키지에 의존하지 않으므로 조립 계층이 참조할 수 있습니다.",
)

private let incorrectResult = ChoiceAnswerResult(
    correct: false,
    answerIndex: 0,
    explanation: "Domain은 다른 패키지에 의존하지 않으므로 조립 계층이 참조할 수 있습니다.",
)

private let essayResult = EssayAnswerResult(
    explanation: "생성자 주입은 의존성을 타입 시그니처로 드러내 테스트 대체를 쉽게 만듭니다.",
    rubric: Rubric(criteria: ["의존성 노출 여부를 설명했습니다", "테스트 대체 용이성을 언급했습니다"]),
)

#Preview("문제 풀이 · 미선택 · s03") {
    ScreenContainer { _ in
        QuestionSolvingScreen(store: previewStore(previewState()))
    }
}

#Preview("문제 풀이 · 출처 Sheet · s04") {
    ScreenContainer { _ in
        QuestionSolvingScreen(store: previewStore(previewState(isSourceSheetPresented: true)))
    }
}

#Preview("문제 풀이 · 선택 · s05") {
    ScreenContainer { _ in
        QuestionSolvingScreen(store: previewStore(previewState(draftChoiceIndex: 1)))
    }
}

#Preview("문제 풀이 · 제출 중 · s06") {
    ScreenContainer { _ in
        QuestionSolvingScreen(
            store: previewStore(previewState(submission: .submitting, draftChoiceIndex: 1))
        )
    }
}

#Preview("문제 풀이 · 제출 실패 · s07") {
    ScreenContainer { _ in
        QuestionSolvingScreen(
            store: previewStore(
                previewState(submission: .failed(.temporarilyUnavailable), draftChoiceIndex: 1)
            )
        )
    }
}

#Preview("문제 풀이 · 정답 · s08") {
    ScreenContainer { _ in
        QuestionSolvingScreen(
            store: previewStore(
                previewState(submission: .answered(.choice(correctResult)), draftChoiceIndex: 0)
            )
        )
    }
}

#Preview("문제 풀이 · 오답 · s09") {
    ScreenContainer { _ in
        QuestionSolvingScreen(
            store: previewStore(
                previewState(submission: .answered(.choice(incorrectResult)), draftChoiceIndex: 2)
            )
        )
    }
}

#Preview("서술형 · 빈 입력 · s10") {
    ScreenContainer { _ in
        QuestionSolvingScreen(store: previewStore(previewState(question: essayQuestion)))
    }
}

#Preview("서술형 · 입력 중 · s11") {
    ScreenContainer { _ in
        QuestionSolvingScreen(
            store: previewStore(
                previewState(
                    question: essayQuestion,
                    draftEssayText: "생성자 주입은 필요한 의존성을 타입 시그니처에 드러냅니다.",
                )
            )
        )
    }
}

#Preview("서술형 · 결과 · s12") {
    ScreenContainer { _ in
        QuestionSolvingScreen(
            store: previewStore(
                previewState(
                    question: essayQuestion,
                    submission: .answered(.essay(essayResult)),
                    draftEssayText: "생성자 주입은 필요한 의존성을 타입 시그니처에 드러냅니다.",
                )
            )
        )
    }
}

#Preview("문제 풀이 · 순번 없는 단일 문제") {
    ScreenContainer { _ in
        QuestionSolvingScreen(
            store: previewStore(
                previewState(questionNumber: nil, questionCount: nil, advanceActionTitle: "완료")
            )
        )
    }
}
