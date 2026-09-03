import DomainLearningProject
import Testing

@testable import Feature

@Suite("QuizLevelSelectionFeature")
struct QuizLevelSelectionFeatureTests {

    @Test
    func `levelSelected는 선택한 값을 반영한다`() async {
        let store = makeQuizLevelSelectionStore()

        for level in QuizLevel.allCases {
            await store.send(.view(.levelSelected(level))) {
                $0.quizLevel = level
            }
        }
    }

    @Test
    func `nextTapped는 현재 선택한 값을 confirmed로 위임한다`() async {
        let store = makeQuizLevelSelectionStore(state: QuizLevelSelectionFeature.State(quizLevel: .l3))

        await store.send(.view(.nextTapped))
        await store.receive(.delegate(.confirmed(.l3)))
    }

    @Test
    func `backTapped는 선택을 유지한 채 backRequested를 위임한다`() async {
        let store = makeQuizLevelSelectionStore(state: QuizLevelSelectionFeature.State(quizLevel: .l2))

        await store.send(.view(.backTapped))
        await store.receive(.delegate(.backRequested))

        #expect(store.state.quizLevel == .l2)
    }

}
