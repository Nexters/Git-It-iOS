import Testing

@testable import DomainAuthentication

// MARK: - VerifyAuthorizationTests

@Suite("VerifyAuthorization")
struct VerifyAuthorizationTests {
    @Test
    func `재인증이 필요하면 세션과 자격 증명을 정리한다`() async {
        let recorder = VerifyAuthorizationCallRecorder()
        let verifyAuthorization = makeVerifyAuthorization(
            status: .reauthenticationRequired,
            recorder: recorder,
        )

        let status = await verifyAuthorization()

        #expect(status == .reauthenticationRequired)
        #expect(await recorder.snapshot() == [.authorizationStatus, .signOut, .clearAuthentication])
    }

    @Test
    func `인증된 상태면 아무것도 정리하지 않는다`() async {
        let recorder = VerifyAuthorizationCallRecorder()
        let verifyAuthorization = makeVerifyAuthorization(
            status: .authorized,
            recorder: recorder,
        )

        let status = await verifyAuthorization()

        #expect(status == .authorized)
        #expect(await recorder.snapshot() == [.authorizationStatus])
    }

    @Test
    func `일시적으로 확인할 수 없으면 아무것도 정리하지 않는다`() async {
        let recorder = VerifyAuthorizationCallRecorder()
        let verifyAuthorization = makeVerifyAuthorization(
            status: .temporarilyUnavailable,
            recorder: recorder,
        )

        let status = await verifyAuthorization()

        #expect(status == .temporarilyUnavailable)
        #expect(await recorder.snapshot() == [.authorizationStatus])
    }

    @Test
    func `상태 조회가 실패하면 일시적으로 확인할 수 없는 상태로 바꾼다`() async {
        let recorder = VerifyAuthorizationCallRecorder()
        let verifyAuthorization = makeVerifyAuthorization(
            status: nil,
            recorder: recorder,
        )

        let status = await verifyAuthorization()

        #expect(status == .temporarilyUnavailable)
        #expect(await recorder.snapshot() == [.authorizationStatus])
    }

    @Test
    func `세션 정리가 실패해도 반환 값이 바뀌지 않는다`() async {
        let recorder = VerifyAuthorizationCallRecorder()
        let verifyAuthorization = makeVerifyAuthorization(
            status: .reauthenticationRequired,
            signOutFails: true,
            recorder: recorder,
        )

        let status = await verifyAuthorization()

        #expect(status == .reauthenticationRequired)
        #expect(await recorder.snapshot() == [.authorizationStatus, .signOut, .clearAuthentication])
    }
}

extension VerifyAuthorizationTests {
    private func makeVerifyAuthorization(
        status: AuthorizationStatus?,
        signOutFails: Bool = false,
        recorder: VerifyAuthorizationCallRecorder,
    ) -> VerifyAuthorization {
        VerifyAuthorization(
            authenticationRepository: VerifyAuthorizationAuthenticationRepository(
                status: status,
                recorder: recorder,
            ),
            loginSessionRepository: VerifyAuthorizationLoginSessionRepository(
                signOutFails: signOutFails,
                recorder: recorder,
            ),
        )
    }
}

// MARK: - VerifyAuthorizationCallRecorder

private actor VerifyAuthorizationCallRecorder {

    // MARK: Internal

    enum Call: Equatable, Sendable {
        case authorizationStatus
        case signOut
        case clearAuthentication
    }

    func append(_ call: Call) {
        calls.append(call)
    }

    func snapshot() -> [Call] {
        calls
    }

    // MARK: Private

    private var calls = [Call]()

}

// MARK: - VerifyAuthorizationAuthenticationRepository

private actor VerifyAuthorizationAuthenticationRepository: AuthenticationRepository {

    // MARK: Lifecycle

    init(
        status: AuthorizationStatus?,
        recorder: VerifyAuthorizationCallRecorder,
    ) {
        self.status = status
        self.recorder = recorder
    }

    // MARK: Internal

    func authenticate(using _: AuthenticationMethod) async throws -> AuthenticationGrant {
        throw AuthenticationError.temporarilyUnavailable
    }

    func authorizationStatus() async throws -> AuthorizationStatus {
        await recorder.append(.authorizationStatus)
        guard let status else {
            throw AuthenticationError.temporarilyUnavailable
        }
        return status
    }

    func clearAuthentication() async throws {
        await recorder.append(.clearAuthentication)
    }

    // MARK: Private

    private let recorder: VerifyAuthorizationCallRecorder
    private let status: AuthorizationStatus?

}

// MARK: - VerifyAuthorizationLoginSessionRepository

private actor VerifyAuthorizationLoginSessionRepository: LoginSessionRepository {

    // MARK: Lifecycle

    init(
        signOutFails: Bool,
        recorder: VerifyAuthorizationCallRecorder,
    ) {
        self.signOutFails = signOutFails
        self.recorder = recorder
    }

    // MARK: Internal

    func start(with _: AuthenticationGrant) async throws -> AuthenticatedUser {
        throw LoginSessionError.temporarilyUnavailable
    }

    func restore() async throws -> AuthenticatedUser? {
        nil
    }

    func signOut() async throws {
        await recorder.append(.signOut)
        if signOutFails {
            throw LoginSessionError.temporarilyUnavailable
        }
    }

    func currentSession() async -> SessionRecord? {
        nil
    }

    func replaceTokens(_: SessionTokens) async throws { }
    func updateOnboarding(_: LocalOnboardingState) async throws { }
    func refresh() async throws -> SessionTokens {
        throw LoginSessionError.temporarilyUnavailable
    }

    func verifyAccessToken() async throws { }

    // MARK: Private

    private let recorder: VerifyAuthorizationCallRecorder
    private let signOutFails: Bool

}
