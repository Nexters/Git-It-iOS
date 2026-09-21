import ComposableArchitecture
import Testing

@testable import Feature

@MainActor
@Suite("AccountActionFeature 로그아웃과 계정 삭제")
struct AccountActionFeatureTests {

    // MARK: Internal

    @Test
    func `로그아웃 성공은 대기 상태로 되돌리고 signedOut을 보낸다`() async {
        let signOut = AccountUseCaseSignOutMock(results: [.signedOut])
        let store = makeStore(signOut: signOut)

        await store.send(.input(.signOutRequested)) {
            $0.accountAction = .signingOut
        }
        await store.receive(.effect(.signOutFinished(.signedOut))) {
            $0.accountAction = .idle
        }
        await store.receive(.delegate(.signedOut))

        #expect(await signOut.snapshot() == 1)
    }

    @Test
    func `로그아웃이 실패해도 다시 로그아웃할 수 있다`() async {
        let signOut = AccountUseCaseSignOutMock(results: [.retryableFailure, .signedOut])
        let store = makeStore(signOut: signOut)

        await store.send(.input(.signOutRequested)) {
            $0.accountAction = .signingOut
        }
        await store.receive(.effect(.signOutFinished(.retryableFailure))) {
            $0.accountAction = .failed(.temporarilyUnavailable)
        }

        await store.send(.input(.signOutRequested)) {
            $0.accountAction = .signingOut
        }
        await store.receive(.effect(.signOutFinished(.signedOut))) {
            $0.accountAction = .idle
        }
        await store.receive(.delegate(.signedOut))

        #expect(await signOut.snapshot() == 2)
    }

    @Test
    func `진행 중인 계정 작업은 새 로그아웃·삭제 요청으로 덮이지 않는다`() async {
        let signOut = AccountUseCaseSignOutMock()
        let withdraw = AccountUseCaseWithdrawalMock()
        let store = makeStore(
            state: AccountActionFeature.State(accountAction: .signingOut),
            signOut: signOut,
            withdraw: withdraw,
        )

        await store.send(.input(.signOutRequested))
        await store.send(.input(.deletionRequested))

        #expect(await signOut.snapshot() == 0)
        #expect(await withdraw.snapshot() == 0)
    }

    @Test
    func `삭제 요청은 확인 단계로 바꾸고 deletionConfirmationRequested를 보낸다`() async {
        let withdraw = AccountUseCaseWithdrawalMock()
        let store = makeStore(withdraw: withdraw)

        await store.send(.input(.deletionRequested)) {
            $0.accountAction = .confirmingDeletion
        }
        await store.receive(.delegate(.deletionConfirmationRequested))

        #expect(await withdraw.snapshot() == 0)
    }

    @Test
    func `삭제 취소는 확인 상태를 해제하고 deletionCancelled를 보낸다`() async {
        let store = makeStore(state: AccountActionFeature.State(accountAction: .confirmingDeletion))

        await store.send(.input(.deletionCancelled)) {
            $0.accountAction = .idle
        }
        await store.receive(.delegate(.deletionCancelled))
    }

    @Test
    func `확인 단계를 거치지 않은 삭제 확인은 계정을 삭제하지 않는다`() async {
        let withdraw = AccountUseCaseWithdrawalMock()
        let store = makeStore(withdraw: withdraw)

        await store.send(.input(.deletionConfirmed))

        #expect(await withdraw.snapshot() == 0)
    }

    @Test
    func `삭제 성공은 대기 상태로 되돌리고 accountDeleted를 보낸다`() async {
        let withdraw = AccountUseCaseWithdrawalMock()
        let store = makeStore(
            state: AccountActionFeature.State(accountAction: .confirmingDeletion),
            withdraw: withdraw,
        )

        await store.send(.input(.deletionConfirmed)) {
            $0.accountAction = .deletingAccount
        }
        await store.receive(.effect(.deleteAccountFinished(nil))) {
            $0.accountAction = .idle
        }
        await store.receive(.delegate(.accountDeleted))

        #expect(await withdraw.snapshot() == 1)
    }

    @Test
    func `삭제가 실패해도 다시 삭제를 진행할 수 있다`() async {
        let withdraw = AccountUseCaseWithdrawalMock(shouldThrow: true)
        let store = makeStore(
            state: AccountActionFeature.State(accountAction: .confirmingDeletion),
            withdraw: withdraw,
        )

        await store.send(.input(.deletionConfirmed)) {
            $0.accountAction = .deletingAccount
        }
        await store.receive(.effect(.deleteAccountFinished(.temporarilyUnavailable))) {
            $0.accountAction = .failed(.temporarilyUnavailable)
        }

        await store.send(.input(.deletionConfirmed)) {
            $0.accountAction = .deletingAccount
        }
        await store.receive(.effect(.deleteAccountFinished(.temporarilyUnavailable))) {
            $0.accountAction = .failed(.temporarilyUnavailable)
        }

        #expect(await withdraw.snapshot() == 2)
    }

    // MARK: Private

    private func makeStore(
        state: AccountActionFeature.State = AccountActionFeature.State(),
        signOut: AccountUseCaseSignOutMock = AccountUseCaseSignOutMock(),
        withdraw: AccountUseCaseWithdrawalMock = AccountUseCaseWithdrawalMock(),
    ) -> TestStoreOf<AccountActionFeature> {
        TestStore(initialState: state) {
            AccountActionFeature(signOut: signOut.signOut, withdraw: withdraw.withdraw)
        }
    }

}
