import DomainAccount
import DomainUserInfo
import Testing

@testable import Feature

@Suite("AppEntryFeature 목적지 판단")
struct AppEntryFeatureTests {

    // MARK: Internal

    @Test
    func `로그인 복구가 미인증이면 온보딩 안내부터 시작하도록 위임하고 restoreSignIn을 한 번만 호출한다`() async {
        let restoreSession = AccountUseCaseRestorationMock(results: [.signedOut])
        let store = makeAppEntryStore(restoreSession: restoreSession)

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.receive(.effect(.restoreSignInFinished(requestID: 1, result: .signedOut))) {
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
    func `스플래시 애니메이션이 먼저 끝나도 로그인 복구 완료 시점에 라우팅된다`() async {
        let restoreSession = AccountUseCaseRestorationMock(results: [.signedOut])
        let store = makeAppEntryStore(restoreSession: restoreSession)

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.send(.view(.splashAnimationFinished)) {
            $0.isSplashAnimationFinished = true
        }
        await store.receive(.effect(.restoreSignInFinished(requestID: 1, result: .signedOut))) {
            $0.authentication = .idle
        }
        await store.receive(.delegate(.destinationDecided(.onboarding(startingAt: .guide))))
    }

    @Test
    func `로그인 복구 실패는 자동으로 1회 재시도한 뒤 재시도 가능한 오류로 전환된다`() async {
        let restoreSession = AccountUseCaseRestorationMock(results: [.temporarilyUnavailable])
        let store = makeAppEntryStore(restoreSession: restoreSession)

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.receive(.effect(.restoreSignInFinished(requestID: 1, result: .temporarilyUnavailable))) {
            $0.automaticRetryCount = 1
            $0.requestID = 2
        }
        await store.receive(.effect(.restoreSignInFinished(requestID: 2, result: .temporarilyUnavailable))) {
            $0.authentication = .retryableFailure
        }

        #expect(await restoreSession.snapshot() == 2)
    }

    @Test
    func `자동 재시도 중 복구에 성공하면 재시도 가능한 오류를 노출하지 않는다`() async {
        let restoreSession = AccountUseCaseRestorationMock(results: [.temporarilyUnavailable, .signedOut])
        let store = makeAppEntryStore(restoreSession: restoreSession)

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.receive(.effect(.restoreSignInFinished(requestID: 1, result: .temporarilyUnavailable))) {
            $0.automaticRetryCount = 1
            $0.requestID = 2
        }
        await store.receive(.effect(.restoreSignInFinished(requestID: 2, result: .signedOut))) {
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
    func `인증이 만료된 큐레이션 조회 실패는 자동 재시도 없이 재시도 가능한 오류로 전환된다`() async {
        let restoreSession = AccountUseCaseRestorationMock(results: [.signedIn(signedInAccount)])
        let fetchMemberProfile = UserInfoUseCaseProfileMock(results: [.failure(.unauthorized)])
        let store = makeAppEntryStore(
            restoreSession: restoreSession,
            fetchMemberProfile: fetchMemberProfile,
        )

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.receive(.effect(.restoreSignInFinished(requestID: 1, result: .signedIn(signedInAccount))))
        await store.receive(.effect(.curationFetchFinished(requestID: 1, result: .failure(.unauthorized)))) {
            $0.authentication = .retryableFailure
        }

        #expect(await restoreSession.snapshot() == 1)
        #expect(await fetchMemberProfile.snapshot() == 1)
    }

    @Test
    func `인증 만료가 아닌 큐레이션 조회 실패는 자동으로 복구를 다시 시도한다`() async {
        let profile = OnboardingTestFixture.profile(position: .ios, careerLevel: .junior)
        let restoreSession = AccountUseCaseRestorationMock(results: [.signedIn(signedInAccount)])
        let fetchMemberProfile = UserInfoUseCaseProfileMock(
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
        await store.receive(.effect(.restoreSignInFinished(requestID: 1, result: .signedIn(signedInAccount))))
        await store.receive(.effect(.curationFetchFinished(requestID: 1, result: .failure(.temporarilyUnavailable)))) {
            $0.automaticRetryCount = 1
            $0.requestID = 2
        }
        await store.receive(.effect(.restoreSignInFinished(requestID: 2, result: .signedIn(signedInAccount))))
        await store.receive(.effect(.curationFetchFinished(requestID: 2, result: .success(profile.curation)))) {
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
        let restoreSession = AccountUseCaseRestorationMock(results: [.signedOut])
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
        await store.receive(.effect(.restoreSignInFinished(requestID: 1, result: .signedOut))) {
            $0.authentication = .idle
        }
        await store.receive(.delegate(.destinationDecided(.onboarding(startingAt: .guide))))
    }

    @Test
    func `복구 중 재시도 탭은 무시되고 restoreSignIn을 추가로 호출하지 않는다`() async {
        let restoreSession = AccountUseCaseRestorationMock(results: [.signedOut])
        let store = makeAppEntryStore(restoreSession: restoreSession)

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.send(.view(.retryTapped))
        await store.receive(.effect(.restoreSignInFinished(requestID: 1, result: .signedOut))) {
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
    func `로그인된 계정의 사용자 정보 404는 로컬 정리 성공 후 온보딩 안내부터 시작하도록 위임한다`() async {
        let restoreSession = AccountUseCaseRestorationMock(results: [.signedIn(signedInAccount)])
        let fetchMemberProfile = UserInfoUseCaseProfileMock(results: [.failure(.memberUnavailable)])
        let signOut = AccountUseCaseSignOutMock(results: [.signedOut])
        let store = makeAppEntryStore(
            restoreSession: restoreSession,
            fetchMemberProfile: fetchMemberProfile,
            signOut: signOut,
        )

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.receive(.effect(.restoreSignInFinished(requestID: 1, result: .signedIn(signedInAccount))))
        await store.receive(.effect(.curationFetchFinished(requestID: 1, result: .failure(.memberUnavailable))))
        await store.receive(.effect(.localCleanupFinished(requestID: 1, result: .signedOut))) {
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
    func `사용자 정보 404 로컬 정리 실패는 자동 재시도를 모두 쓴 뒤 재시도 가능한 오류로 유지한다`() async {
        let restoreSession = AccountUseCaseRestorationMock(results: [.signedIn(signedInAccount)])
        let fetchMemberProfile = UserInfoUseCaseProfileMock(results: [.failure(.memberUnavailable)])
        let signOut = AccountUseCaseSignOutMock(results: [.retryableFailure])
        let store = makeAppEntryStore(
            restoreSession: restoreSession,
            fetchMemberProfile: fetchMemberProfile,
            signOut: signOut,
        )

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.receive(.effect(.restoreSignInFinished(requestID: 1, result: .signedIn(signedInAccount))))
        await store.receive(.effect(.curationFetchFinished(requestID: 1, result: .failure(.memberUnavailable))))
        await store.receive(.effect(.localCleanupFinished(requestID: 1, result: .retryableFailure))) {
            $0.automaticRetryCount = 1
            $0.requestID = 2
        }
        await store.receive(.effect(.restoreSignInFinished(requestID: 2, result: .signedIn(signedInAccount))))
        await store.receive(.effect(.curationFetchFinished(requestID: 2, result: .failure(.memberUnavailable))))
        await store.receive(.effect(.localCleanupFinished(requestID: 2, result: .retryableFailure))) {
            $0.authentication = .retryableFailure
        }

        #expect(await signOut.snapshot() == 2)
    }

    @Test
    func `큐레이션이 없는 사용자 정보는 큐레이션부터 시작하도록 위임한다`() async {
        let restoreSession = AccountUseCaseRestorationMock(results: [.signedIn(signedInAccount)])
        let fetchMemberProfile = UserInfoUseCaseProfileMock(
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
        await store.receive(.effect(.restoreSignInFinished(requestID: 1, result: .signedIn(signedInAccount))))
        await store.receive(.effect(.curationFetchFinished(requestID: 1, result: .success(nil)))) {
            $0.pendingDestination = .onboarding(startingAt: .curation)
        }
        await store.send(.view(.splashAnimationFinished)) {
            $0.isSplashAnimationFinished = true
            $0.pendingDestination = nil
        }
        await store.receive(.delegate(.destinationDecided(.onboarding(startingAt: .curation))))
    }

    @Test
    func `큐레이션이 있는 사용자 정보는 MainShell로 시작하도록 위임한다`() async {
        let restoreSession = AccountUseCaseRestorationMock(results: [.signedIn(signedInAccount)])
        let profile = OnboardingTestFixture.profile(position: .ios, careerLevel: .junior)
        let fetchMemberProfile = UserInfoUseCaseProfileMock(results: [.success(profile)])
        let store = makeAppEntryStore(
            restoreSession: restoreSession,
            fetchMemberProfile: fetchMemberProfile,
        )

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.receive(.effect(.restoreSignInFinished(requestID: 1, result: .signedIn(signedInAccount))))
        await store.receive(.effect(.curationFetchFinished(requestID: 1, result: .success(profile.curation)))) {
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
        let store = makeAppEntryStore(restoreSession: AccountUseCaseRestorationMock(results: [.signedOut]))

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.send(.effect(.restoreSignInFinished(requestID: 999, result: .signedOut)))
        await store.receive(.effect(.restoreSignInFinished(requestID: 1, result: .signedOut))) {
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
        let restoreSession = AccountUseCaseRestorationMock(results: [.signedOut])
        let store = makeAppEntryStore(restoreSession: restoreSession)

        await store.send(.view(.task)) {
            $0.authentication = .restoring
            $0.requestID = 1
        }
        await store.send(.view(.splashAnimationFinished)) {
            $0.isSplashAnimationFinished = true
        }
        await store.receive(.effect(.restoreSignInFinished(requestID: 1, result: .signedOut))) {
            $0.authentication = .idle
        }
        await store.receive(.delegate(.destinationDecided(.onboarding(startingAt: .guide))))

        await store.send(.view(.splashAnimationFinished))
    }

    // MARK: Private

    private let signedInAccount = OnboardingTestFixture.signedInAccount(needsCuration: false)

}
