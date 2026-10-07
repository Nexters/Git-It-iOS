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
        try await repository.clearAuthentication()

        #expect(grant == expectedGrant)
        #expect(status == .authorized)
        #expect(
            await repository.recordedCalls() == [
                .authenticate(.apple),
                .authorizationStatus,
                .clearAuthentication,
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
        case clearAuthentication
    }

    func authenticate(using method: AuthenticationMethod) async throws -> AuthenticationGrant {
        calls.append(.authenticate(method))
        return grant
    }

    func authorizationStatus() async throws -> AuthorizationStatus {
        calls.append(.authorizationStatus)
        return .authorized
    }

    func clearAuthentication() async throws {
        calls.append(.clearAuthentication)
    }

    func recordedCalls() -> [Call] {
        calls
    }

    // MARK: Private

    private let grant: AuthenticationGrant
    private var calls = [Call]()

}
