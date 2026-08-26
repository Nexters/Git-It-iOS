import DomainAuthentication
import DomainMember
import Testing

@testable import Feature

@Suite("OnboardingFeature curation")
struct OnboardingCurationTests {

    @Test
    func `position 선택은 지원하는 네 값 중 하나만 저장하고 career 단계로 전환한다`() async {
        var state = OnboardingFeature.State(bundleVersion: "1.0.0")
        state.phase = .position
        let store = makeOnboardingStore(state: state)

        await store.send(.view(.positionSelected(.backend))) {
            $0.curation.position = .backend
            $0.phase = .career
        }
    }

    @Test
    func `career 선택 뒤 position으로 되돌아가면 두 선택을 모두 보존한다`() async {
        var state = OnboardingFeature.State(bundleVersion: "1.0.0")
        state.phase = .career
        state.curation.position = .frontend
        state.curation.careerLevel = .junior
        let store = makeOnboardingStore(state: state)

        await store.send(.view(.careerBackTapped)) {
            $0.phase = .position
        }

        #expect(store.state.curation.position == .frontend)
        #expect(store.state.curation.careerLevel == .junior)
    }

    @Test
    func `position에서 뒤로 가기는 sign-out 성공 시 tutorial 3페이지로 이동하고 선택을 초기화한다`() async {
        var state = OnboardingFeature.State(bundleVersion: "1.0.0")
        state.phase = .position
        state.authentication = .success
        state.curation.position = .ios
        let signOut = SignOutUseCaseMock(results: [.success])
        let store = makeOnboardingStore(signOut: signOut, state: state)

        await store.send(.view(.positionBackTapped)) {
            $0.positionExitStatus = .inProgress
        }
        await store.receive(.effect(.positionExitSignOutFinished(.success))) {
            $0.positionExitStatus = .idle
            $0.authentication = .idle
            $0.curation = OnboardingFeature.CurationSelection()
            $0.phase = .tutorial(page: 3)
        }

        #expect(await signOut.snapshot() == 1)
    }

    @Test
    func `position에서 뒤로 가기는 sign-out 실패 시 오류를 유지하고 재시도할 수 있다`() async {
        var state = OnboardingFeature.State(bundleVersion: "1.0.0")
        state.phase = .position
        state.authentication = .success
        let signOut = SignOutUseCaseMock(results: [.retryableFailure, .success])
        let store = makeOnboardingStore(signOut: signOut, state: state)

        await store.send(.view(.positionBackTapped)) {
            $0.positionExitStatus = .inProgress
        }
        await store.receive(.effect(.positionExitSignOutFinished(.retryableFailure))) {
            $0.positionExitStatus = .failed
        }

        // 오류 상태에서도 phase는 position에 남아 재시도할 수 있다.
        #expect(store.state.phase == .position)

        await store.send(.view(.positionBackTapped)) {
            $0.positionExitStatus = .inProgress
        }
        await store.receive(.effect(.positionExitSignOutFinished(.success))) {
            $0.positionExitStatus = .idle
            $0.authentication = .idle
            $0.curation = OnboardingFeature.CurationSelection()
            $0.phase = .tutorial(page: 3)
        }

        #expect(await signOut.snapshot() == 2)
    }

    @Test
    func `curation 제출 중 중복 제출은 무시하고 completeCuration을 한 번만 호출한다`() async {
        var state = OnboardingFeature.State(bundleVersion: "1.0.0")
        state.phase = .career
        state.curation.position = .ios
        state.curation.careerLevel = .junior
        let completeCuration = CompleteCurationUseCaseMock(results: [.success(())])
        let store = makeOnboardingStore(completeCuration: completeCuration, state: state)

        await store.send(.view(.curationSubmitTapped)) {
            $0.curation.submission = .submitting
        }
        await store.send(.view(.curationSubmitTapped))
        await store.receive(.effect(.curationFinished(success: true))) {
            $0.curation.submission = .idle
            $0.phase = .completing
        }
        await store.receive(.delegate(.mainShellRequested))

        #expect(await completeCuration.snapshot() == [.init(position: .ios, careerLevel: .junior)])
    }

    @Test
    func `curation 제출 실패는 선택을 보존하고 재시도로 성공하면 MainShell delegate를 보낸다`() async {
        var state = OnboardingFeature.State(bundleVersion: "1.0.0")
        state.phase = .career
        state.curation.position = .android
        state.curation.careerLevel = .senior
        let completeCuration = CompleteCurationUseCaseMock(results: [.failure(.temporarilyUnavailable), .success(())])
        let store = makeOnboardingStore(completeCuration: completeCuration, state: state)

        await store.send(.view(.curationSubmitTapped)) {
            $0.curation.submission = .submitting
        }
        await store.receive(.effect(.curationFinished(success: false))) {
            $0.curation.submission = .failed
        }

        #expect(store.state.curation.position == .android)
        #expect(store.state.curation.careerLevel == .senior)

        await store.send(.view(.curationSubmitTapped)) {
            $0.curation.submission = .submitting
        }
        await store.receive(.effect(.curationFinished(success: true))) {
            $0.curation.submission = .idle
            $0.phase = .completing
        }
        await store.receive(.delegate(.mainShellRequested))

        #expect(await completeCuration.snapshot().count == 2)
    }

}
