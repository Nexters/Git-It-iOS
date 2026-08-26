import DomainAuthentication
import DomainMember
import Testing

@testable import Feature

@Suite("OnboardingFeature 세션 복구")
struct OnboardingRestoreTests {

    @Test
    func `세션 복구가 미인증이면 tutorial 첫 페이지로 전환하고 restoreSession을 한 번만 호출한다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.unauthenticated])
        let store = makeOnboardingStore(restoreSession: restoreSession)

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.receive(.effect(.restoreSessionFinished(requestID: 1, result: .unauthenticated))) {
            $0.authentication = .idle
            $0.phase = .tutorial(page: 1)
        }

        #expect(await restoreSession.snapshot() == 1)
    }

    @Test
    func `세션 복구 실패는 restoreError로 전환되고 retry는 splash를 거쳐 다시 복구를 시도한다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.recoverableFailure, .unauthenticated])
        let store = makeOnboardingStore(restoreSession: restoreSession)

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.receive(.effect(.restoreSessionFinished(requestID: 1, result: .recoverableFailure))) {
            $0.authentication = .retryableFailure
            $0.phase = .restoreError
        }

        await store.send(.view(.retryRestoreTapped)) {
            $0.phase = .splash
            $0.authentication = .restoring
            $0.requestID = 2
        }
        await store.receive(.effect(.restoreSessionFinished(requestID: 2, result: .unauthenticated))) {
            $0.authentication = .idle
            $0.phase = .tutorial(page: 1)
        }

        #expect(await restoreSession.snapshot() == 2)
    }

    @Test
    func `복구 중 재시도 탭은 무시되고 restoreSession을 추가로 호출하지 않는다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.unauthenticated])
        let store = makeOnboardingStore(restoreSession: restoreSession)

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.send(.view(.retryRestoreTapped))
        await store.receive(.effect(.restoreSessionFinished(requestID: 1, result: .unauthenticated))) {
            $0.authentication = .idle
            $0.phase = .tutorial(page: 1)
        }

        #expect(await restoreSession.snapshot() == 1)
    }

    @Test
    func `인증된 세션의 member 404는 로컬 정리 성공 후 tutorial 첫 페이지로 전환한다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.authenticated(OnboardingTestFixture.authenticatedUser)])
        let fetchMemberProfile = FetchMemberProfileUseCaseMock(results: [.failure(.memberUnavailable)])
        let signOut = SignOutUseCaseMock(results: [.success])
        let store = makeOnboardingStore(
            restoreSession: restoreSession,
            signOut: signOut,
            fetchMemberProfile: fetchMemberProfile,
        )

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.receive(
            .effect(.restoreSessionFinished(requestID: 1, result: .authenticated(OnboardingTestFixture.authenticatedUser)))
        ) {
            $0.authentication = .success
        }
        await store.receive(.effect(.memberProfileFetchFinished(requestID: 1, result: .failure(.memberUnavailable))))
        await store.receive(.effect(.localCleanupFinished(requestID: 1, result: .success))) {
            $0.authentication = .idle
            $0.phase = .tutorial(page: 1)
        }

        #expect(await signOut.snapshot() == 1)
    }

    @Test
    func `member 404 로컬 정리 실패는 restoreError로 유지하고 신규 가입으로 진행하지 않는다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.authenticated(OnboardingTestFixture.authenticatedUser)])
        let fetchMemberProfile = FetchMemberProfileUseCaseMock(results: [.failure(.memberUnavailable)])
        let signOut = SignOutUseCaseMock(results: [.retryableFailure])
        let store = makeOnboardingStore(
            restoreSession: restoreSession,
            signOut: signOut,
            fetchMemberProfile: fetchMemberProfile,
        )

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.receive(
            .effect(.restoreSessionFinished(requestID: 1, result: .authenticated(OnboardingTestFixture.authenticatedUser)))
        ) {
            $0.authentication = .success
        }
        await store.receive(.effect(.memberProfileFetchFinished(requestID: 1, result: .failure(.memberUnavailable))))
        await store.receive(.effect(.localCleanupFinished(requestID: 1, result: .retryableFailure))) {
            $0.authentication = .retryableFailure
            $0.phase = .restoreError
        }
    }

    @Test
    func `position 또는 careerLevel이 null인 profile은 두 선택을 초기화하고 position 단계로 전환한다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.authenticated(OnboardingTestFixture.authenticatedUser)])
        let fetchMemberProfile = FetchMemberProfileUseCaseMock(
            results: [.success(OnboardingTestFixture.profile(position: .ios, careerLevel: nil))]
        )
        let store = makeOnboardingStore(
            restoreSession: restoreSession,
            fetchMemberProfile: fetchMemberProfile,
        )

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.receive(
            .effect(.restoreSessionFinished(requestID: 1, result: .authenticated(OnboardingTestFixture.authenticatedUser)))
        ) {
            $0.authentication = .success
        }
        await store.receive(
            .effect(
                .memberProfileFetchFinished(
                    requestID: 1,
                    result: .success(OnboardingTestFixture.profile(position: .ios, careerLevel: nil)),
                )
            )
        ) {
            $0.phase = .position
        }
    }

    @Test
    func `position과 careerLevel이 모두 있는 profile은 completing을 거쳐 MainShell delegate를 보낸다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.authenticated(OnboardingTestFixture.authenticatedUser)])
        let profile = OnboardingTestFixture.profile(position: .ios, careerLevel: .junior)
        let fetchMemberProfile = FetchMemberProfileUseCaseMock(results: [.success(profile)])
        let store = makeOnboardingStore(
            restoreSession: restoreSession,
            fetchMemberProfile: fetchMemberProfile,
        )

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.receive(
            .effect(.restoreSessionFinished(requestID: 1, result: .authenticated(OnboardingTestFixture.authenticatedUser)))
        ) {
            $0.authentication = .success
        }
        await store.receive(.effect(.memberProfileFetchFinished(requestID: 1, result: .success(profile)))) {
            $0.phase = .completing
        }
        await store.receive(.delegate(.mainShellRequested))
    }

    @Test
    func `현재 requestID와 다른 복구 응답은 상태를 바꾸지 않는다`() async {
        let store = makeOnboardingStore()

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.send(.effect(.restoreSessionFinished(requestID: 999, result: .unauthenticated)))
        await store.receive(.effect(.restoreSessionFinished(requestID: 1, result: .unauthenticated))) {
            $0.authentication = .idle
            $0.phase = .tutorial(page: 1)
        }
    }

}
