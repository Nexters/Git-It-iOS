import DomainAuthentication
import DomainMember
import Testing

@testable import Feature

@Suite("AppEntryFeature 목적지 판단")
struct AppEntryFeatureTests {

    @Test
    func `세션 복구가 미인증이면 온보딩 안내부터 시작하도록 위임하고 restoreSession을 한 번만 호출한다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.unauthenticated])
        let store = makeAppEntryStore(restoreSession: restoreSession)

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.receive(.effect(.restoreSessionFinished(requestID: 1, result: .unauthenticated))) {
            $0.authentication = .idle
            $0.pendingDestination = .onboarding(startingAt: .guide)
        }
        await store.send(.view(.splashAnimationFinished)) {
            $0.isSplashAnimationFinished = true
            $0.pendingDestination = nil
        }
        await store.receive(.delegate(.destinationDecided(.onboarding(startingAt: .guide))))

        #expect(await restoreSession.snapshot() == 1)
    }

    @Test
    func `스플래시 애니메이션이 먼저 끝나도 세션 인증 완료 시점에 라우팅된다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.unauthenticated])
        let store = makeAppEntryStore(restoreSession: restoreSession)

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.send(.view(.splashAnimationFinished)) {
            $0.isSplashAnimationFinished = true
        }
        await store.receive(.effect(.restoreSessionFinished(requestID: 1, result: .unauthenticated))) {
            $0.authentication = .idle
        }
        await store.receive(.delegate(.destinationDecided(.onboarding(startingAt: .guide))))
    }

    @Test
    func `세션 복구 실패는 자동으로 1회 재시도한 뒤 재시도 가능한 오류로 전환된다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.recoverableFailure])
        let store = makeAppEntryStore(restoreSession: restoreSession)

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.receive(.effect(.restoreSessionFinished(requestID: 1, result: .recoverableFailure))) {
            $0.automaticRetryCount = 1
            $0.requestID = 2
        }
        await store.receive(.effect(.restoreSessionFinished(requestID: 2, result: .recoverableFailure))) {
            $0.authentication = .retryableFailure
        }

        #expect(await restoreSession.snapshot() == 2)
    }

    @Test
    func `자동 재시도 중 복구에 성공하면 재시도 가능한 오류를 노출하지 않는다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.recoverableFailure, .unauthenticated])
        let store = makeAppEntryStore(restoreSession: restoreSession)

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.receive(.effect(.restoreSessionFinished(requestID: 1, result: .recoverableFailure))) {
            $0.automaticRetryCount = 1
            $0.requestID = 2
        }
        await store.receive(.effect(.restoreSessionFinished(requestID: 2, result: .unauthenticated))) {
            $0.authentication = .idle
            $0.pendingDestination = .onboarding(startingAt: .guide)
        }
        await store.send(.view(.splashAnimationFinished)) {
            $0.isSplashAnimationFinished = true
            $0.pendingDestination = nil
        }
        await store.receive(.delegate(.destinationDecided(.onboarding(startingAt: .guide))))

        #expect(await restoreSession.snapshot() == 2)
    }

    @Test
    func `토큰이 만료된 프로필 조회 실패는 자동 재시도 없이 재시도 가능한 오류로 전환된다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.authenticated(OnboardingTestFixture.authenticatedUser)])
        let fetchMemberProfile = FetchMemberProfileUseCaseMock(results: [.failure(.unauthorized)])
        let store = makeAppEntryStore(
            restoreSession: restoreSession,
            fetchMemberProfile: fetchMemberProfile,
        )

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.receive(
            .effect(.restoreSessionFinished(requestID: 1, result: .authenticated(OnboardingTestFixture.authenticatedUser)))
        )
        await store.receive(.effect(.memberProfileFetchFinished(requestID: 1, result: .failure(.unauthorized)))) {
            $0.authentication = .retryableFailure
        }

        #expect(await restoreSession.snapshot() == 1)
        #expect(await fetchMemberProfile.snapshot() == 1)
    }

    @Test
    func `토큰 만료가 아닌 프로필 조회 실패는 자동으로 복구를 다시 시도한다`() async {
        let profile = OnboardingTestFixture.profile(position: .ios, careerLevel: .junior)
        let restoreSession = RestoreSessionUseCaseMock(results: [.authenticated(OnboardingTestFixture.authenticatedUser)])
        let fetchMemberProfile = FetchMemberProfileUseCaseMock(
            results: [.failure(.temporarilyUnavailable), .success(profile)]
        )
        let store = makeAppEntryStore(
            restoreSession: restoreSession,
            fetchMemberProfile: fetchMemberProfile,
        )

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.receive(
            .effect(.restoreSessionFinished(requestID: 1, result: .authenticated(OnboardingTestFixture.authenticatedUser)))
        )
        await store.receive(
            .effect(.memberProfileFetchFinished(requestID: 1, result: .failure(.temporarilyUnavailable)))
        ) {
            $0.automaticRetryCount = 1
            $0.requestID = 2
        }
        await store.receive(
            .effect(.restoreSessionFinished(requestID: 2, result: .authenticated(OnboardingTestFixture.authenticatedUser)))
        )
        await store.receive(.effect(.memberProfileFetchFinished(requestID: 2, result: .success(profile)))) {
            $0.pendingDestination = .mainShell
        }
        await store.send(.view(.splashAnimationFinished)) {
            $0.isSplashAnimationFinished = true
            $0.pendingDestination = nil
        }
        await store.receive(.delegate(.destinationDecided(.mainShell)))
    }

    @Test
    func `스플래시 애니메이션이 끝난 뒤 재시도하면 자동 재시도 횟수를 초기화하고 곧바로 라우팅한다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.unauthenticated])
        var exhaustedState = AppEntryFeature.State()
        exhaustedState.authentication = .retryableFailure
        exhaustedState.isSplashAnimationFinished = true
        exhaustedState.automaticRetryCount = 1
        let store = makeAppEntryStore(restoreSession: restoreSession, state: exhaustedState)

        await store.send(.view(.retryTapped)) {
            $0.authentication = .restoring
            $0.automaticRetryCount = 0
            $0.requestID = 1
        }
        await store.receive(.effect(.restoreSessionFinished(requestID: 1, result: .unauthenticated))) {
            $0.authentication = .idle
        }
        await store.receive(.delegate(.destinationDecided(.onboarding(startingAt: .guide))))
    }

    @Test
    func `복구 중 재시도 탭은 무시되고 restoreSession을 추가로 호출하지 않는다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.unauthenticated])
        let store = makeAppEntryStore(restoreSession: restoreSession)

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.send(.view(.retryTapped))
        await store.receive(.effect(.restoreSessionFinished(requestID: 1, result: .unauthenticated))) {
            $0.authentication = .idle
            $0.pendingDestination = .onboarding(startingAt: .guide)
        }
        await store.send(.view(.splashAnimationFinished)) {
            $0.isSplashAnimationFinished = true
            $0.pendingDestination = nil
        }
        await store.receive(.delegate(.destinationDecided(.onboarding(startingAt: .guide))))

        #expect(await restoreSession.snapshot() == 1)
    }

    @Test
    func `인증된 세션의 member 404는 로컬 정리 성공 후 온보딩 안내부터 시작하도록 위임한다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.authenticated(OnboardingTestFixture.authenticatedUser)])
        let fetchMemberProfile = FetchMemberProfileUseCaseMock(results: [.failure(.memberUnavailable)])
        let signOut = SignOutUseCaseMock(results: [.success])
        let store = makeAppEntryStore(
            restoreSession: restoreSession,
            fetchMemberProfile: fetchMemberProfile,
            signOut: signOut,
        )

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.receive(
            .effect(.restoreSessionFinished(requestID: 1, result: .authenticated(OnboardingTestFixture.authenticatedUser)))
        )
        await store.receive(.effect(.memberProfileFetchFinished(requestID: 1, result: .failure(.memberUnavailable))))
        await store.receive(.effect(.localCleanupFinished(requestID: 1, result: .success))) {
            $0.authentication = .idle
            $0.pendingDestination = .onboarding(startingAt: .guide)
        }
        await store.send(.view(.splashAnimationFinished)) {
            $0.isSplashAnimationFinished = true
            $0.pendingDestination = nil
        }
        await store.receive(.delegate(.destinationDecided(.onboarding(startingAt: .guide))))

        #expect(await signOut.snapshot() == 1)
    }

    @Test
    func `member 404 로컬 정리 실패는 자동 재시도를 모두 쓴 뒤 재시도 가능한 오류로 유지한다`() async {
        let user = OnboardingTestFixture.authenticatedUser
        let restoreSession = RestoreSessionUseCaseMock(results: [.authenticated(user)])
        let fetchMemberProfile = FetchMemberProfileUseCaseMock(results: [.failure(.memberUnavailable)])
        let signOut = SignOutUseCaseMock(results: [.retryableFailure])
        let store = makeAppEntryStore(
            restoreSession: restoreSession,
            fetchMemberProfile: fetchMemberProfile,
            signOut: signOut,
        )

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.receive(.effect(.restoreSessionFinished(requestID: 1, result: .authenticated(user))))
        await store.receive(.effect(.memberProfileFetchFinished(requestID: 1, result: .failure(.memberUnavailable))))
        await store.receive(.effect(.localCleanupFinished(requestID: 1, result: .retryableFailure))) {
            $0.automaticRetryCount = 1
            $0.requestID = 2
        }
        await store.receive(.effect(.restoreSessionFinished(requestID: 2, result: .authenticated(user))))
        await store.receive(.effect(.memberProfileFetchFinished(requestID: 2, result: .failure(.memberUnavailable))))
        await store.receive(.effect(.localCleanupFinished(requestID: 2, result: .retryableFailure))) {
            $0.authentication = .retryableFailure
        }

        #expect(await signOut.snapshot() == 2)
    }

    @Test
    func `position 또는 careerLevel이 null인 profile은 큐레이션부터 시작하도록 위임한다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.authenticated(OnboardingTestFixture.authenticatedUser)])
        let fetchMemberProfile = FetchMemberProfileUseCaseMock(
            results: [.success(OnboardingTestFixture.profile(position: .ios, careerLevel: nil))]
        )
        let store = makeAppEntryStore(
            restoreSession: restoreSession,
            fetchMemberProfile: fetchMemberProfile,
        )

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.receive(
            .effect(.restoreSessionFinished(requestID: 1, result: .authenticated(OnboardingTestFixture.authenticatedUser)))
        )
        await store.receive(
            .effect(
                .memberProfileFetchFinished(
                    requestID: 1,
                    result: .success(OnboardingTestFixture.profile(position: .ios, careerLevel: nil)),
                )
            )
        ) {
            $0.pendingDestination = .onboarding(startingAt: .curation)
        }
        await store.send(.view(.splashAnimationFinished)) {
            $0.isSplashAnimationFinished = true
            $0.pendingDestination = nil
        }
        await store.receive(.delegate(.destinationDecided(.onboarding(startingAt: .curation))))
    }

    @Test
    func `position과 careerLevel이 모두 있는 profile은 MainShell로 시작하도록 위임한다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.authenticated(OnboardingTestFixture.authenticatedUser)])
        let profile = OnboardingTestFixture.profile(position: .ios, careerLevel: .junior)
        let fetchMemberProfile = FetchMemberProfileUseCaseMock(results: [.success(profile)])
        let store = makeAppEntryStore(
            restoreSession: restoreSession,
            fetchMemberProfile: fetchMemberProfile,
        )

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.receive(
            .effect(.restoreSessionFinished(requestID: 1, result: .authenticated(OnboardingTestFixture.authenticatedUser)))
        )
        await store.receive(.effect(.memberProfileFetchFinished(requestID: 1, result: .success(profile)))) {
            $0.pendingDestination = .mainShell
        }
        await store.send(.view(.splashAnimationFinished)) {
            $0.isSplashAnimationFinished = true
            $0.pendingDestination = nil
        }
        await store.receive(.delegate(.destinationDecided(.mainShell)))
    }

    @Test
    func `현재 requestID와 다른 복구 응답은 상태를 바꾸지 않는다`() async {
        let store = makeAppEntryStore()

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.send(.effect(.restoreSessionFinished(requestID: 999, result: .unauthenticated)))
        await store.receive(.effect(.restoreSessionFinished(requestID: 1, result: .unauthenticated))) {
            $0.authentication = .idle
            $0.pendingDestination = .onboarding(startingAt: .guide)
        }
        await store.send(.view(.splashAnimationFinished)) {
            $0.isSplashAnimationFinished = true
            $0.pendingDestination = nil
        }
        await store.receive(.delegate(.destinationDecided(.onboarding(startingAt: .guide))))
    }

    @Test
    func `애니메이션 완료 신호가 중복으로 와도 라우팅은 한 번만 일어난다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.unauthenticated])
        let store = makeAppEntryStore(restoreSession: restoreSession)

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.send(.view(.splashAnimationFinished)) {
            $0.isSplashAnimationFinished = true
        }
        await store.receive(.effect(.restoreSessionFinished(requestID: 1, result: .unauthenticated))) {
            $0.authentication = .idle
        }
        await store.receive(.delegate(.destinationDecided(.onboarding(startingAt: .guide))))

        await store.send(.view(.splashAnimationFinished))
    }

}
