import Foundation
import Testing

@testable import DomainUseCaseImplementation
@testable import DomainUseCaseInterface

@Suite("Account")
struct AccountTests {

    // MARK: Internal

    @Test
    func `로그인 상태 구독의 첫 값은 unknown이다`() async {
        let account = Self.makeAccount()

        var states = await account.signInStates().makeAsyncIterator()

        let state = await states.next()
        #expect(state == .unknown)
    }

    @Test
    func `로그인에 성공하면 계정을 반환하고 signedIn 상태를 방출한다`() async {
        let account = Self.makeAccount()
        var states = await account.signInStates().makeAsyncIterator()
        _ = await states.next()

        let result = await account.signIn(with: .apple)

        #expect(result == .signedIn(StubSignInRepository.account))
        let state = await states.next()
        #expect(state == .signedIn("account-1"))
    }

    @Test
    func `사용자가 인증을 취소하면 cancelled를 반환한다`() async {
        let account = Self.makeAccount(
            authenticationRepository: StubAuthenticationRepository(authenticateResult: .failure(.signInCancelled))
        )

        #expect(await account.signIn(with: .apple) == .cancelled)
    }

    @Test
    func `로그인 기록 시작에 실패하면 인증을 정리하고 retryableFailure를 반환한다`() async {
        let authenticationRepository = StubAuthenticationRepository()
        let account = Self.makeAccount(
            authenticationRepository: authenticationRepository,
            signInRepository: StubSignInRepository(startResult: .failure(.temporarilyUnavailable)),
        )

        #expect(await account.signIn(with: .apple) == .retryableFailure)
        #expect(await authenticationRepository.clearAuthenticationCount == 1)
    }

    @Test
    func `로그아웃에 성공하면 signedOut 상태를 방출한다`() async {
        let account = Self.makeAccount()
        var states = await account.signInStates().makeAsyncIterator()
        _ = await states.next()

        #expect(await account.signOut() == .signedOut)
        let state = await states.next()
        #expect(state == .signedOut)
    }

    @Test
    func `로그인 기록 정리에 실패하면 로그아웃은 retryableFailure를 반환한다`() async {
        let account = Self.makeAccount(signInRepository: StubSignInRepository(signOutError: .temporarilyUnavailable))

        #expect(await account.signOut() == .retryableFailure)
    }

    @Test
    func `복원이 일시적으로 실패하면 unknown 상태를 유지한다`() async {
        let account = Self.makeAccount(
            signInRepository: StubSignInRepository(restoreResult: .failure(.temporarilyUnavailable))
        )

        #expect(await account.restoreSignIn() == .temporarilyUnavailable)

        var states = await account.signInStates().makeAsyncIterator()
        let state = await states.next()
        #expect(state == .unknown)
    }

    @Test
    func `복원할 로그인 기록이 없으면 signedOut으로 전환한다`() async {
        let authenticationRepository = StubAuthenticationRepository()
        let account = Self.makeAccount(
            authenticationRepository: authenticationRepository,
            signInRepository: StubSignInRepository(restoreResult: .success(nil)),
        )

        #expect(await account.restoreSignIn() == .signedOut)
        #expect(await authenticationRepository.clearAuthenticationCount == 1)

        var states = await account.signInStates().makeAsyncIterator()
        let state = await states.next()
        #expect(state == .signedOut)
    }

    @Test
    func `무효한 로그인 기록을 복원하면 기록을 정리하고 signedOut을 반환한다`() async {
        let signInRepository = StubSignInRepository(restoreResult: .failure(.unauthorized))
        let account = Self.makeAccount(signInRepository: signInRepository)

        #expect(await account.restoreSignIn() == .signedOut)
        #expect(await signInRepository.signOutCount == 1)
    }

    @Test
    func `사용할 수 없는 계정을 복원하면 기록을 정리하고 signedOut을 반환한다`() async {
        let record = SignInRecord(
            account: StubSignInRepository.account,
            isAccountAvailable: false,
        )
        let signInRepository = StubSignInRepository(restoreResult: .success(record))
        let account = Self.makeAccount(signInRepository: signInRepository)

        #expect(await account.restoreSignIn() == .signedOut)
        #expect(await signInRepository.signOutCount == 1)
    }

    @Test
    func `인증이 유효하면 복원한 계정으로 signedIn 상태가 된다`() async {
        let account = Self.makeAccount()

        #expect(await account.restoreSignIn() == .signedIn(StubSignInRepository.account))

        var states = await account.signInStates().makeAsyncIterator()
        let state = await states.next()
        #expect(state == .signedIn("account-1"))
    }

    @Test
    func `복원 중 재인증이 필요하면 기록을 정리하고 signedOut을 반환한다`() async {
        let signInRepository = StubSignInRepository()
        let account = Self.makeAccount(
            authenticationRepository: StubAuthenticationRepository(authorizationResult: .success(.reauthenticationRequired)),
            signInRepository: signInRepository,
        )

        #expect(await account.restoreSignIn() == .signedOut)
        #expect(await signInRepository.signOutCount == 1)
    }

    @Test
    func `인증 확인이 실패하면 temporarilyUnavailable을 반환한다`() async {
        let account = Self.makeAccount(
            authenticationRepository: StubAuthenticationRepository(authorizationResult: .failure(.temporarilyUnavailable))
        )

        #expect(await account.verifySignIn() == .temporarilyUnavailable)
    }

    @Test
    func `인증 확인에서 재인증이 필요하면 기록을 정리하고 signedOut 상태를 방출한다`() async {
        let signInRepository = StubSignInRepository()
        let account = Self.makeAccount(
            authenticationRepository: StubAuthenticationRepository(authorizationResult: .success(.reauthenticationRequired)),
            signInRepository: signInRepository,
        )
        var states = await account.signInStates().makeAsyncIterator()
        _ = await states.next()

        #expect(await account.verifySignIn() == .reauthenticationRequired)
        #expect(await signInRepository.signOutCount == 1)
        let state = await states.next()
        #expect(state == .signedOut)
    }

    @Test
    func `로그인 무효 신호를 받으면 기록을 정리하고 signedOut 상태를 방출한다`() async {
        let (invalidations, invalidationContinuation) = AsyncStream<Void>.makeStream()
        let signInRepository = StubSignInRepository()
        let account = Self.makeAccount(
            signInRepository: signInRepository,
            signInInvalidations: invalidations,
        )
        _ = await account.signIn(with: .apple)
        var states = await account.signInStates().makeAsyncIterator()
        let state = await states.next()
        #expect(state == .signedIn("account-1"))

        invalidationContinuation.yield(())

        let nextState = await states.next()
        #expect(nextState == .signedOut)
        #expect(await signInRepository.signOutCount == 1)
    }

    // MARK: Private

    private static func makeAccount(
        authenticationRepository: StubAuthenticationRepository = StubAuthenticationRepository(),
        signInRepository: StubSignInRepository = StubSignInRepository(),
        signInInvalidations: AsyncStream<Void> = AsyncStream { _ in },
    ) -> Account {
        Account(
            authenticationRepository: authenticationRepository,
            signInRepository: signInRepository,
            withdrawalRepository: StubWithdrawalRepository(),
            policyConsentRepository: InMemoryPolicyConsentRepository(),
            policyDocuments: [],
            signInInvalidations: { signInInvalidations },
        )
    }

}
