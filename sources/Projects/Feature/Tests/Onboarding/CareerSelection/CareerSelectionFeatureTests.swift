import DomainMember
import Testing

@testable import Feature

@Suite("CareerSelectionFeature")
struct CareerSelectionFeatureTests {

    @Test
    func `career 선택은 값을 저장하고 뒤로 가기는 backRequested를 위임한다`() async {
        var state = CareerSelectionFeature.State()
        state.position = .frontend
        let store = makeCareerSelectionStore(state: state)

        await store.send(.view(.careerLevelSelected(.junior))) {
            $0.careerLevel = .junior
        }
        await store.send(.view(.backTapped))
        await store.receive(.delegate(.backRequested))

        #expect(store.state.careerLevel == .junior)
    }

    @Test
    func `curation 제출 중 중복 제출은 무시하고 completeCuration을 한 번만 호출한다`() async {
        var state = CareerSelectionFeature.State()
        state.position = .ios
        state.careerLevel = .junior
        let completeCuration = CompleteCurationUseCaseMock(results: [.success(())])
        let store = makeCareerSelectionStore(completeCuration: completeCuration, state: state)

        await store.send(.view(.submitTapped)) {
            $0.submission = .submitting
        }
        await store.send(.view(.submitTapped))
        await store.receive(.effect(.curationFinished(success: true))) {
            $0.submission = .idle
        }
        await store.receive(.delegate(.curationSucceeded))

        #expect(await completeCuration.snapshot() == [.init(position: .ios, careerLevel: .junior)])
    }

    @Test
    func `curation 제출 실패는 선택을 보존하고 재시도로 성공하면 curationSucceeded를 위임한다`() async {
        var state = CareerSelectionFeature.State()
        state.position = .android
        state.careerLevel = .senior
        let completeCuration = CompleteCurationUseCaseMock(results: [.failure(.temporarilyUnavailable), .success(())])
        let store = makeCareerSelectionStore(completeCuration: completeCuration, state: state)

        await store.send(.view(.submitTapped)) {
            $0.submission = .submitting
        }
        await store.receive(.effect(.curationFinished(success: false))) {
            $0.submission = .failed
        }

        #expect(store.state.careerLevel == .senior)

        await store.send(.view(.submitTapped)) {
            $0.submission = .submitting
        }
        await store.receive(.effect(.curationFinished(success: true))) {
            $0.submission = .idle
        }
        await store.receive(.delegate(.curationSucceeded))

        #expect(await completeCuration.snapshot().count == 2)
    }

}
