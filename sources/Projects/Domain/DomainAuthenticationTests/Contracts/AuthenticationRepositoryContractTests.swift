import Testing

@testable import DomainAuthentication

// MARK: - AuthenticationRepositoryContractTests

@Suite("AuthenticationRepository 계약")
struct AuthenticationRepositoryContractTests {
    @Test
    func `외부 인증과 권한 상태 및 인증 참조 정리만 제공한다`() async throws {
        let expectedGrant = AuthenticationGrant(
            id: .init(rawValue: "grant-1"),
            method: .apple,
        )
        let repository = AuthenticationRepositoryContractProbe(grant: expectedGrant)

        let grant = try await repository.authenticate(using: .apple)
        let status = try await repository.authorizationStatus()
        let changes = await repository.authorizationChanges()
        var iterator = changes.makeAsyncIterator()
        let change = await iterator.next()
        try await repository.clearAuthorization()

        #expect(grant == expectedGrant)
        #expect(status == .authorized)
        #expect(change == .reauthenticationRequired)
        #expect(
            await repository.recordedCalls() == [
                .authenticate(.apple),
                .authorizationStatus,
                .authorizationChanges,
                .clearAuthorization,
            ]
        )
    }
}

// MARK: - AuthenticationRepositoryContractProbe

private actor AuthenticationRepositoryContractProbe: AuthenticationRepository {

    // MARK: Lifecycle

    init(grant: AuthenticationGrant) {
        self.grant = grant
    }

    // MARK: Internal

    enum Call: Equatable, Sendable {
        case authenticate(AuthenticationMethod)
        case authorizationStatus
        case authorizationChanges
        case clearAuthorization
    }

    func authenticate(using method: AuthenticationMethod) async throws -> AuthenticationGrant {
        calls.append(.authenticate(method))
        return grant
    }

    func authorizationStatus() async throws -> AuthenticationAuthorizationStatus {
        calls.append(.authorizationStatus)
        return .authorized
    }

    func authorizationChanges() async -> AsyncStream<AuthenticationAuthorizationStatus> {
        calls.append(.authorizationChanges)
        return AsyncStream { continuation in
            continuation.yield(.reauthenticationRequired)
            continuation.finish()
        }
    }

    func clearAuthorization() async throws {
        calls.append(.clearAuthorization)
    }

    func recordedCalls() -> [Call] {
        calls
    }

    // MARK: Private

    private let grant: AuthenticationGrant
    private var calls = [Call]()

}
