import ComposableArchitecture
import DomainLearningProject
import SwiftUI

private let previewSet = LearningSet(
    setID: "set-1",
    title: "의존성 주입과 모듈 경계",
    description: "이 세트에서는 모듈 사이의 의존 방향과 주입 지점을 확인합니다.",
    questions: [
        Question(
            questionID: "question-1",
            prompt: "Composition 패키지가 Domain에 의존해도 되는 이유는 무엇인가?",
            format: .multipleChoice,
            choices: ["의존 방향이 단방향이기 때문", "진입점이기 때문", "UI를 포함하기 때문", "제약이 없기 때문"],
            sources: [],
            myAnswer: nil,
        )
    ],
)

private func previewState(activeScreen: QuizRouterFeature.ActiveScreen) -> QuizRouterFeature.State {
    var state = QuizRouterFeature.State(projectID: "project-1", setID: "set-1", setLabel: "CHAPTER 1")
    state.learningSetIntro.setLoad = .loaded(previewSet)
    state.learningSet = previewSet
    state.resumption = LearningSetResumption(set: previewSet)
    state.questionSolving = QuestionSolvingFeature.State(
        projectID: "project-1",
        question: previewSet.questions[0],
        questionNumber: 1,
        advanceActionTitle: QuizRouterFeature.completeActionTitle,
    )
    state.learningCompletion.choiceQuestionCount = 1
    state.learningCompletion.correctChoiceCount = 1
    state.activeScreen = activeScreen
    return state
}

#Preview("풀이 흐름 · 세트 소개") {
    QuizRouter(store: Store(initialState: previewState(activeScreen: .learningSetIntro)) { EmptyReducer() })
}

#Preview("풀이 흐름 · 문제 풀이") {
    QuizRouter(store: Store(initialState: previewState(activeScreen: .questionSolving)) { EmptyReducer() })
}

#Preview("풀이 흐름 · 학습 완료") {
    QuizRouter(store: Store(initialState: previewState(activeScreen: .learningCompletion)) { EmptyReducer() })
}
