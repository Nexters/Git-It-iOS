import DomainUserInfo
import Testing

@testable import Feature

@MainActor
@Suite("CareerSelectionFeature")
struct CareerSelectionFeatureTests {

    @Test
    func `positionProvided 입력은 제출에 쓸 직군을 저장한다`() async {
        let store = makeCareerSelectionStore()

        await store.send(.input(.positionProvided(.backend))) {
            $0 = CareerSelectionFeature.State(position: .backend)
        }
    }

    @Test
    func `career 선택은 값을 저장하고 뒤로 가기는 backRequested를 위임한다`() async {
        let state = CareerSelectionFeature.State(position: .frontend)
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
        var state = CareerSelectionFeature.State(position: .ios)
        state.careerLevel = .junior
        let completeCuration = UserInfoUseCaseCurationMock(results: [.success(())], suspendsRequests: true)
        let store = makeCareerSelectionStore(completeCuration: completeCuration, state: state)

        await store.send(.view(.submitTapped)) {
            $0.submission = .submitting
        }
        await store.send(.view(.submitTapped))
        await completeCuration.resumeOldest()
        await store.receive(.effect(.curationFinished(success: true))) {
            $0.submission = .idle
        }
        await store.receive(.delegate(.curationSucceeded))

        #expect(await completeCuration.snapshot() == [Curation(position: .ios, careerLevel: .junior)])
    }

    @Test
    func `curation 제출 실패는 선택을 보존하고 재시도로 성공하면 curationSucceeded를 위임한다`() async {
        var state = CareerSelectionFeature.State(position: .android)
        state.careerLevel = .senior
        let completeCuration = UserInfoUseCaseCurationMock(results: [.failure(.temporarilyUnavailable), .success(())])
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
