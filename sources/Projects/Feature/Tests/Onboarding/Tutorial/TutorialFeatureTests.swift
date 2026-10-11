import Testing

@testable import Feature

@MainActor
@Suite("TutorialFeature")
struct TutorialFeatureTests {

    // MARK: Internal

    @Test
    func `tutorial 페이지 변경은 현재 페이지 값만 갱신한다`() async {
        let store = makeTutorialStore()

        await store.send(.view(.pageChanged(2))) {
            $0.page = 2
        }
    }

    @Test
    func `화면 진입은 로그인에 prepareConsent를 보낸다`() async {
        let store = makeTutorialStore(state: consentCheckedState())

        await store.send(.view(.appeared))
        await store.receive(.signIn(.input(.prepareConsent)))
    }

    @Test
    func `Apple 로그인 성공은 needsCuration을 그대로 위임한다`() async {
        let signIn = AccountUseCaseSignInMock(results: [.signedIn(curatedAccount)])
        let store = makeTutorialStore(
            signIn: signIn,
            state: consentCheckedState(),
        )

        await store.send(.view(.appleSignInTapped))
        await store.receive(.signIn(.input(.start))) {
            $0.signIn.phase = .signingIn
            $0.signIn.requestID = 1
        }
        await store.receive(.signIn(.effect(.signInFinished(
            requestID: 1,
            result: .signedIn(curatedAccount),
        )))) {
            $0.signIn.phase = .idle
        }
        await store.receive(.signIn(.delegate(.signedIn(needsCuration: false))))
        await store.receive(.delegate(.signInSucceeded(needsCuration: false)))

        #expect(await signIn.snapshot() == [.apple])
    }

    @Test
    func `로그인 진행 중 중복 탭은 추가 로그인 호출을 만들지 않는다`() async {
        let signIn = AccountUseCaseSignInMock(
            results: [.retryableFailure],
            suspendsRequests: true,
        )
        let store = makeTutorialStore(
            signIn: signIn,
            state: consentCheckedState(),
        )

        await store.send(.view(.appleSignInTapped))
        await store.receive(.signIn(.input(.start))) {
            $0.signIn.phase = .signingIn
            $0.signIn.requestID = 1
        }
        await store.send(.view(.appleSignInTapped))
        await signIn.resumeOldest()
        await store.receive(.signIn(.effect(.signInFinished(
            requestID: 1,
            result: .retryableFailure,
        )))) {
            $0.signIn.phase = .failed
        }

        #expect(store.state.isShowingRecoverableError)
        #expect(await signIn.snapshot() == [.apple])
    }

    @Test
    func `Apple 인증 취소는 재시도 오류와 구분되는 cancelled 상태로 남는다`() async {
        let signIn = AccountUseCaseSignInMock(results: [.cancelled])
        let store = makeTutorialStore(
            signIn: signIn,
            state: consentCheckedState(),
        )

        await store.send(.view(.appleSignInTapped))
        await store.receive(.signIn(.input(.start))) {
            $0.signIn.phase = .signingIn
            $0.signIn.requestID = 1
        }
        await store.receive(.signIn(.effect(.signInFinished(
            requestID: 1,
            result: .cancelled,
        )))) {
            $0.signIn.phase = .cancelled
        }
        await store.receive(.signIn(.delegate(.signInCancelled)))

        #expect(store.state.isShowingRecoverableError)
    }

    @Test
    func `첫 페이지에서 Apple 로그인을 누르면 페이지 이동 없이 바로 로그인을 시작한다`() async {
        var state = consentCheckedState()
        state.page = 1
        let store = makeTutorialStore(
            signIn: AccountUseCaseSignInMock(
                results: [.retryableFailure],
                suspendsRequests: true,
            ),
            state: state,
        )
        store.exhaustivity = .off

        await store.send(.view(.appleSignInTapped))
        await store.receive(.signIn(.input(.start)))

        #expect(store.state.page == 1)
        #expect(store.state.isSigningIn)
    }

    @Test
    func `약관 동의를 취소하면 현재 페이지를 유지한다`() async {
        var state = TutorialFeature.State(bundleVersion: "1.0.0")
        state.page = 1
        let store = makeTutorialStore(state: state)

        await store.send(.signIn(.delegate(.consentCancelled)))
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
        let signIn = AccountUseCaseSignInMock(results: [.signedIn(curatedAccount), .signedIn(uncuratedAccount)])
        let accountWithdrawal = AccountUseCaseWithdrawalMock()
        let store = makeTutorialStore(
            signIn: signIn,
            accountWithdrawal: accountWithdrawal,
            deletesCompletedAccountOnSignIn: true,
            state: consentCheckedState(),
        )

        await store.send(.view(.appleSignInTapped))
        await store.receive(.signIn(.input(.start))) {
            $0.signIn.phase = .signingIn
            $0.signIn.requestID = 1
        }
        await store.receive(.signIn(.effect(.signInFinished(
            requestID: 1,
            result: .signedIn(curatedAccount),
        )))) {
            $0.signIn.phase = .idle
        }
        await store.receive(.signIn(.delegate(.signedIn(needsCuration: false)))) {
            $0.hasAttemptedCompletedAccountReset = true
            $0.accountReset = .resetting
        }
        await store.receive(.effect(.accountResetFinished)) {
            $0.accountReset = .idle
        }
        await store.receive(.signIn(.input(.start))) {
            $0.signIn.phase = .signingIn
            $0.signIn.requestID = 2
        }
        await store.receive(.signIn(.effect(.signInFinished(
            requestID: 2,
            result: .signedIn(uncuratedAccount),
        )))) {
            $0.signIn.phase = .idle
        }
        await store.receive(.signIn(.delegate(.signedIn(needsCuration: true))))
        await store.receive(.delegate(.signInSucceeded(needsCuration: true)))

        #expect(await signIn.snapshot() == [.apple, .apple])
        #expect(await accountWithdrawal.snapshot() == 1)
    }

    @Test
    func `deletesCompletedAccountOnSignIn이 true여도 재시도가 다시 needsCuration false를 받으면 더 이상 반복하지 않는다`() async {
        let signIn = AccountUseCaseSignInMock(results: [.signedIn(curatedAccount), .signedIn(curatedAccount)])
        let accountWithdrawal = AccountUseCaseWithdrawalMock()
        let store = makeTutorialStore(
            signIn: signIn,
            accountWithdrawal: accountWithdrawal,
            deletesCompletedAccountOnSignIn: true,
            state: consentCheckedState(),
        )

        await store.send(.view(.appleSignInTapped))
        await store.receive(.signIn(.input(.start))) {
            $0.signIn.phase = .signingIn
            $0.signIn.requestID = 1
        }
        await store.receive(.signIn(.effect(.signInFinished(
            requestID: 1,
            result: .signedIn(curatedAccount),
        )))) {
            $0.signIn.phase = .idle
        }
        await store.receive(.signIn(.delegate(.signedIn(needsCuration: false)))) {
            $0.hasAttemptedCompletedAccountReset = true
            $0.accountReset = .resetting
        }
        await store.receive(.effect(.accountResetFinished)) {
            $0.accountReset = .idle
        }
        await store.receive(.signIn(.input(.start))) {
            $0.signIn.phase = .signingIn
            $0.signIn.requestID = 2
        }
        await store.receive(.signIn(.effect(.signInFinished(
            requestID: 2,
            result: .signedIn(curatedAccount),
        )))) {
            $0.signIn.phase = .idle
        }
        await store.receive(.signIn(.delegate(.signedIn(needsCuration: false))))
        await store.receive(.delegate(.signInSucceeded(needsCuration: false)))

        #expect(await signIn.snapshot() == [.apple, .apple])
        #expect(await accountWithdrawal.snapshot() == 1)
    }

    @Test
    func `첫 페이지에서도 비로그인 진입을 누르면 guestAccessRequested를 위임한다`() async {
        var state = TutorialFeature.State(bundleVersion: "1.0.0")
        state.page = 1
        let store = makeTutorialStore(state: state)

        await store.send(.view(.guestAccessTapped))
        await store.receive(.delegate(.guestAccessRequested))
    }

    @Test
    func `로그인 진행 중에는 비로그인 진입을 무시한다`() async {
        var state = TutorialFeature.State(bundleVersion: "1.0.0")
        state.signIn.phase = .signingIn
        let store = makeTutorialStore(state: state)

        await store.send(.view(.guestAccessTapped))
    }

    @Test
    func `계정 재설정 중에는 로그인 진행 중으로 보고 비로그인 진입을 무시한다`() async {
        var state = TutorialFeature.State(bundleVersion: "1.0.0")
        state.accountReset = .resetting
        let store = makeTutorialStore(state: state)

        #expect(store.state.isSigningIn)
        await store.send(.view(.guestAccessTapped))
    }

    // MARK: Private

    private let curatedAccount = OnboardingTestFixture.signedInAccount(needsCuration: false)
    private let uncuratedAccount = OnboardingTestFixture.signedInAccount(needsCuration: true)

    private func consentCheckedState() -> TutorialFeature.State {
        var state = TutorialFeature.State(bundleVersion: "1.0.0")
        state.signIn.legalAgreement.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.signIn.legalAgreement.isStoredConsentValid = true
        return state
    }

}
