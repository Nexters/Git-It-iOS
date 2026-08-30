import DomainAuthentication
import DomainMember
import Testing

@testable import Feature

@Suite("CurationFeature")
struct CurationFeatureTests {

    @Test
    func `position 선택은 지원하는 네 값 중 하나만 저장하고 단계를 바꾸지 않는다`() async {
        var state = CurationFeature.State()
        state.screen = .position
        let store = makeCurationStore(state: state)

        await store.send(.view(.positionSelected(.backend))) {
            $0.selection.position = .backend
        }

        #expect(store.state.screen == .position)
    }

    @Test
    func `position 미선택 상태의 다음 입력은 career 단계로 전환하지 않는다`() async {
        var state = CurationFeature.State()
        state.screen = .position
        let store = makeCurationStore(state: state)

        await store.send(.view(.positionNextTapped))

        #expect(store.state.screen == .position)
    }

    @Test
    func `position 선택 뒤 다음 입력은 선택을 유지한 채 career 단계로 전환한다`() async {
        var state = CurationFeature.State()
        state.screen = .position
        state.selection.position = .backend
        let store = makeCurationStore(state: state)

        await store.send(.view(.positionNextTapped)) {
            $0.screen = .career
        }

        #expect(store.state.selection.position == .backend)
    }

    @Test
    func `career 선택 뒤 position으로 되돌아가면 두 선택을 모두 보존한다`() async {
        var state = CurationFeature.State()
        state.screen = .career
        state.selection.position = .frontend
        state.selection.careerLevel = .junior
        let store = makeCurationStore(state: state)

        await store.send(.view(.careerBackTapped)) {
            $0.screen = .position
        }

        #expect(store.state.selection.position == .frontend)
        #expect(store.state.selection.careerLevel == .junior)
    }

    @Test
    func `position에서 뒤로 가기는 sign-out 성공 시 exitRequested를 위임하고 선택을 초기화한다`() async {
        var state = CurationFeature.State()
        state.screen = .position
        state.selection.position = .ios
        let signOut = SignOutUseCaseMock(results: [.success])
        let store = makeCurationStore(signOut: signOut, state: state)

        await store.send(.view(.positionBackTapped)) {
            $0.exitStatus = .inProgress
        }
        await store.receive(.effect(.positionExitSignOutFinished(.success))) {
            $0.exitStatus = .idle
        }
        await store.receive(.delegate(.exitRequested))

        #expect(await signOut.snapshot() == 1)
    }

    @Test
    func `position에서 뒤로 가기는 sign-out 실패 시 오류를 유지하고 재시도할 수 있다`() async {
        var state = CurationFeature.State()
        state.screen = .position
        let signOut = SignOutUseCaseMock(results: [.retryableFailure, .success])
        let store = makeCurationStore(signOut: signOut, state: state)

        await store.send(.view(.positionBackTapped)) {
            $0.exitStatus = .inProgress
        }
        await store.receive(.effect(.positionExitSignOutFinished(.retryableFailure))) {
            $0.exitStatus = .failed
        }

        #expect(store.state.screen == .position)

        await store.send(.view(.positionBackTapped)) {
            $0.exitStatus = .inProgress
        }
        await store.receive(.effect(.positionExitSignOutFinished(.success))) {
            $0.exitStatus = .idle
        }
        await store.receive(.delegate(.exitRequested))

        #expect(await signOut.snapshot() == 2)
    }

    @Test
    func `curation 제출 중 중복 제출은 무시하고 completeCuration을 한 번만 호출한다`() async {
        var state = CurationFeature.State()
        state.screen = .career
        state.selection.position = .ios
        state.selection.careerLevel = .junior
        let completeCuration = CompleteCurationUseCaseMock(results: [.success(())])
        let store = makeCurationStore(completeCuration: completeCuration, state: state)

        await store.send(.view(.curationSubmitTapped)) {
            $0.selection.submission = .submitting
        }
        await store.send(.view(.curationSubmitTapped))
        await store.receive(.effect(.curationFinished(success: true))) {
            $0.selection.submission = .idle
        }
        await store.receive(.delegate(.curationSucceeded))

        #expect(await completeCuration.snapshot() == [.init(position: .ios, careerLevel: .junior)])
    }

    @Test
    func `curation 제출 실패는 선택을 보존하고 재시도로 성공하면 curationSucceeded를 위임한다`() async {
        var state = CurationFeature.State()
        state.screen = .career
        state.selection.position = .android
        state.selection.careerLevel = .senior
        let completeCuration = CompleteCurationUseCaseMock(results: [.failure(.temporarilyUnavailable), .success(())])
        let store = makeCurationStore(completeCuration: completeCuration, state: state)

        await store.send(.view(.curationSubmitTapped)) {
            $0.selection.submission = .submitting
        }
        await store.receive(.effect(.curationFinished(success: false))) {
            $0.selection.submission = .failed
        }

        #expect(store.state.selection.position == .android)
        #expect(store.state.selection.careerLevel == .senior)

        await store.send(.view(.curationSubmitTapped)) {
            $0.selection.submission = .submitting
        }
        await store.receive(.effect(.curationFinished(success: true))) {
            $0.selection.submission = .idle
        }
        await store.receive(.delegate(.curationSucceeded))

        #expect(await completeCuration.snapshot().count == 2)
    }

}
