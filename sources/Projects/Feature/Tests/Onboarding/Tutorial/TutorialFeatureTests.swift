import DomainAuthentication
import DomainMember
import Testing

@testable import Feature

@Suite("TutorialFeature")
struct TutorialFeatureTests {

    @Test
    func `tutorial 페이지 변경은 현재 페이지 값만 갱신한다`() async {
        let store = makeTutorialStore()

        await store.send(.view(.pageChanged(2))) {
            $0.page = 2
        }
    }

    @Test
    func `화면 진입은 appeared를 위임한다`() async {
        let store = makeTutorialStore()

        await store.send(.view(.appeared))
        await store.receive(.delegate(.appeared))
    }

    @Test
    func `Apple 로그인 성공은 마지막 페이지로 이동한 뒤 needsCuration을 그대로 위임한다`() async {
        let signIn = SignInUseCaseMock(results: [.success(OnboardingTestFixture.authenticatedUser, needsCuration: false)])
        let store = makeTutorialStore(signIn: signIn)

        await store.send(.view(.appleSignInTapped)) {
            $0.page = 3
            $0.authentication = .signingIn
            $0.requestID = 1
        }
        await store.receive(
            .effect(
                .signInFinished(
                    requestID: 1,
                    result: .success(OnboardingTestFixture.authenticatedUser, needsCuration: false),
                )
            )
        ) {
            $0.authentication = .idle
        }
        await store.receive(.delegate(.signInSucceeded(needsCuration: false)))

        #expect(await signIn.snapshot() == [.apple])
    }

    @Test
    func `로그인 진행 중 중복 탭은 추가 로그인 호출을 만들지 않는다`() async {
        let signIn = SignInUseCaseMock(results: [.retryableFailure])
        let store = makeTutorialStore(signIn: signIn)

        await store.send(.view(.appleSignInTapped)) {
            $0.page = 3
            $0.authentication = .signingIn
            $0.requestID = 1
        }
        await store.send(.view(.appleSignInTapped))
        await store.receive(.effect(.signInFinished(requestID: 1, result: .retryableFailure))) {
            $0.authentication = .retryableFailure
        }

        #expect(await signIn.snapshot() == [.apple])
    }

    @Test
    func `Apple 인증 취소는 재시도 오류와 구분되는 cancelled 상태로 남는다`() async {
        let signIn = SignInUseCaseMock(results: [.cancelled])
        let store = makeTutorialStore(signIn: signIn)

        await store.send(.view(.appleSignInTapped)) {
            $0.page = 3
            $0.authentication = .signingIn
            $0.requestID = 1
        }
        await store.receive(.effect(.signInFinished(requestID: 1, result: .cancelled))) {
            $0.authentication = .cancelled
        }
        #expect(store.state.isShowingRecoverableError)
    }

    @Test
    func `현재 requestID와 다른 로그인 응답은 상태를 바꾸지 않는다`() async {
        let signIn = SignInUseCaseMock(results: [.cancelled])
        let store = makeTutorialStore(signIn: signIn)

        await store.send(.view(.appleSignInTapped)) {
            $0.page = 3
            $0.authentication = .signingIn
            $0.requestID = 1
        }
        await store.send(.effect(.signInFinished(requestID: 999, result: .retryableFailure)))
        await store.receive(.effect(.signInFinished(requestID: 1, result: .cancelled))) {
            $0.authentication = .cancelled
        }
    }

    @Test
    func `returnToLastPage 입력은 마지막 페이지로 되돌린다`() async {
        var state = TutorialFeature.State(bundleVersion: "1.0.0")
        state.page = 1
        let store = makeTutorialStore(state: state)

        await store.send(.input(.returnToLastPage)) {
            $0.page = 3
        }
    }

    @Test
    func `deletesCompletedAccountOnSignIn이 true면 needsCuration false 응답을 받은 뒤 회원탈퇴하고 자동으로 재로그인한다`() async {
        let signIn = SignInUseCaseMock(results: [
            .success(OnboardingTestFixture.authenticatedUser, needsCuration: false),
            .success(OnboardingTestFixture.authenticatedUser, needsCuration: true),
        ])
        let deleteMemberAccount = DeleteMemberAccountUseCaseMock()
        let store = makeTutorialStore(
            signIn: signIn,
            deleteMemberAccount: deleteMemberAccount,
            deletesCompletedAccountOnSignIn: true,
        )

        await store.send(.view(.appleSignInTapped)) {
            $0.page = 3
            $0.authentication = .signingIn
            $0.requestID = 1
        }
        await store.receive(
            .effect(
                .signInFinished(
                    requestID: 1,
                    result: .success(OnboardingTestFixture.authenticatedUser, needsCuration: false),
                )
            )
        ) {
            $0.hasAttemptedCompletedAccountReset = true
            $0.requestID = 2
        }
        await store.receive(
            .effect(
                .signInFinished(
                    requestID: 2,
                    result: .success(OnboardingTestFixture.authenticatedUser, needsCuration: true),
                )
            )
        ) {
            $0.authentication = .idle
        }
        await store.receive(.delegate(.signInSucceeded(needsCuration: true)))

        #expect(await signIn.snapshot() == [.apple, .apple])
        #expect(await deleteMemberAccount.snapshot() == 1)
    }

    @Test
    func `deletesCompletedAccountOnSignIn이 true여도 재시도가 다시 needsCuration false를 받으면 더 이상 반복하지 않는다`() async {
        let signIn = SignInUseCaseMock(results: [
            .success(OnboardingTestFixture.authenticatedUser, needsCuration: false),
            .success(OnboardingTestFixture.authenticatedUser, needsCuration: false),
        ])
        let deleteMemberAccount = DeleteMemberAccountUseCaseMock()
        let store = makeTutorialStore(
            signIn: signIn,
            deleteMemberAccount: deleteMemberAccount,
            deletesCompletedAccountOnSignIn: true,
        )

        await store.send(.view(.appleSignInTapped)) {
            $0.page = 3
            $0.authentication = .signingIn
            $0.requestID = 1
        }
        await store.receive(
            .effect(
                .signInFinished(
                    requestID: 1,
                    result: .success(OnboardingTestFixture.authenticatedUser, needsCuration: false),
                )
            )
        ) {
            $0.hasAttemptedCompletedAccountReset = true
            $0.requestID = 2
        }
        await store.receive(
            .effect(
                .signInFinished(
                    requestID: 2,
                    result: .success(OnboardingTestFixture.authenticatedUser, needsCuration: false),
                )
            )
        ) {
            $0.authentication = .idle
        }
        await store.receive(.delegate(.signInSucceeded(needsCuration: false)))

        #expect(await signIn.snapshot() == [.apple, .apple])
        #expect(await deleteMemberAccount.snapshot() == 1)
    }

}
