import ComposableArchitecture
import Testing

@testable import Feature

@Suite("LearningCompletionFeature 완료 표현")
struct LearningCompletionFeatureTests {

    @Test
    func `객관식이 있으면 점수를 표시하고 접근성 문장으로 읽어 준다`() {
        let state = LearningCompletionFeature.State(
            projectID: "project-1",
            correctChoiceCount: 3,
            choiceQuestionCount: 5,
        )

        #expect(state.isScorePresented)
        #expect(state.scoreAccessibilityLabel == "객관식 5문제 중 3문제 정답")
    }

    @Test
    func `객관식이 없으면 점수를 표시하지 않는다`() {
        let state = LearningCompletionFeature.State(projectID: "project-1")

        #expect(!state.isScorePresented)
        #expect(state.scoreAccessibilityLabel == nil)
    }

    @Test
    func `닫기와 확인은 같은 이탈 요청을 만든다`() async {
        let store = TestStore(initialState: LearningCompletionFeature.State(projectID: "project-1")) {
            LearningCompletionFeature()
        }

        await store.send(.view(.closeTapped))
        await store.receive(.delegate(.dismissRequested))

        await store.send(.view(.primaryActionTapped))
        await store.receive(.delegate(.dismissRequested))
    }

}
