import DomainAuthentication
import DomainMember
import Testing

@testable import Feature

@Suite("PositionSelectionFeature")
struct PositionSelectionFeatureTests {

    @Test
    func `position 선택은 지원하는 네 값 중 하나만 저장한다`() async {
        let store = makePositionSelectionStore()

        await store.send(.view(.positionSelected(.backend))) {
            $0.position = .backend
        }
    }

    @Test
    func `position 미선택 상태의 다음 입력은 confirmed를 위임하지 않는다`() async {
        let store = makePositionSelectionStore()

        await store.send(.view(.nextTapped))
    }

    @Test
    func `position 선택 뒤 다음 입력은 선택을 유지한 채 confirmed를 위임한다`() async {
        var state = PositionSelectionFeature.State()
        state.position = .backend
        let store = makePositionSelectionStore(state: state)

        await store.send(.view(.nextTapped))
        await store.receive(.delegate(.confirmed(.backend)))

        #expect(store.state.position == .backend)
    }

    @Test
    func `뒤로 가기는 sign-out 성공 시 exitRequested를 위임한다`() async {
        var state = PositionSelectionFeature.State()
        state.position = .ios
        let signOut = SignOutUseCaseMock(results: [.success])
        let store = makePositionSelectionStore(signOut: signOut, state: state)

        await store.send(.view(.backTapped)) {
            $0.exitStatus = .inProgress
        }
        await store.receive(.effect(.signOutFinished(.success))) {
            $0.exitStatus = .idle
        }
        await store.receive(.delegate(.exitRequested))

        #expect(await signOut.snapshot() == 1)
    }

    @Test
    func `뒤로 가기는 sign-out 실패 시 오류를 유지하고 재시도할 수 있다`() async {
        let signOut = SignOutUseCaseMock(results: [.retryableFailure, .success])
        let store = makePositionSelectionStore(signOut: signOut)

        await store.send(.view(.backTapped)) {
            $0.exitStatus = .inProgress
        }
        await store.receive(.effect(.signOutFinished(.retryableFailure))) {
            $0.exitStatus = .failed
        }

        await store.send(.view(.backTapped)) {
            $0.exitStatus = .inProgress
        }
        await store.receive(.effect(.signOutFinished(.success))) {
            $0.exitStatus = .idle
        }
        await store.receive(.delegate(.exitRequested))

        #expect(await signOut.snapshot() == 2)
    }

}
