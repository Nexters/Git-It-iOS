import Testing

@testable import DomainAuthentication

// MARK: - LoginSessionRepositoryContractTests

@Suite("LoginSessionRepository 계약")
struct LoginSessionRepositoryContractTests {
    @Test
    func `grant 기반 시작과 복원 및 로그아웃만 제공한다`() async throws {
        let grant = AuthenticationGrant(
            id: .init(rawValue: "grant-1"),
            method: .apple,
        )
        let user = AuthenticatedUser(
            id: "user-1",
            availability: .available,
            displayName: nil,
        )
        let repository = LoginSessionRepositoryContractProbe(user: user)

        let startedUser = try await repository.start(with: grant)
        let restoredUser = try await repository.restore()
        try await repository.signOut()

        #expect(startedUser == user)
        #expect(restoredUser == user)
        #expect(
            await repository.recordedCalls() == [
                .start(grant),
                .restore,
                .signOut,
            ]
        )
    }
}

// MARK: - LoginSessionRepositoryContractProbe

private actor LoginSessionRepositoryContractProbe: LoginSessionRepository {

    // MARK: Lifecycle

    init(user: AuthenticatedUser) {
        self.user = user
    }

    // MARK: Internal

    enum Call: Equatable, Sendable {
        case start(AuthenticationGrant)
        case restore
        case signOut
    }

    func start(with grant: AuthenticationGrant) async throws -> AuthenticatedUser {
        calls.append(.start(grant))
        return user
    }

    func restore() async throws -> AuthenticatedUser? {
        calls.append(.restore)
        return user
    }

    func signOut() async throws {
        calls.append(.signOut)
    }

    func recordedCalls() -> [Call] {
        calls
    }

    // MARK: Private

    private var calls = [Call]()
    private let user: AuthenticatedUser

}
