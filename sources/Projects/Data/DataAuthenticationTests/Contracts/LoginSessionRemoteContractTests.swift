import Foundation
import Testing

@testable import DataAuthentication

// MARK: - LoginSessionRemoteContractTests

@Suite("LoginSessionRemote 계약")
struct LoginSessionRemoteContractTests {
    @Test
    func `세션 시작과 갱신 및 폐기만 제공한다`() async throws {
        let remote = LoginSessionRemoteProbe()
        let response = try await remote.startSession(
            LoginSessionStartRequestDTO(
                methodIdentifier: "social-provider",
                opaquePayload: .init(bytes: [1]),
            )
        )
        let refreshed = try await remote.refreshSession(RefreshRequestDTO(refreshToken: "refresh"))
        try await remote.revokeRefreshToken("refresh")

        #expect(response.user.id == "user-1")
        #expect(refreshed.replacementRefreshToken == nil)
        #expect(await remote.recordedCalls() == [.start, .refresh, .revoke])
    }
}

// MARK: - LoginSessionRemoteProbe

private actor LoginSessionRemoteProbe: LoginSessionRemote {

    // MARK: Internal

    enum Call: Equatable, Sendable { case start, refresh, revoke }

    func startSession(_: LoginSessionStartRequestDTO) async throws -> LoginSessionResponseDTO {
        calls.append(.start)
        return LoginSessionResponseDTO(
            user: .init(
                id: "user-1",
                availability: .available,
                displayName: nil,
            ),
            accessToken: "access",
            refreshToken: "refresh",
            accessExpiresAt: Date(timeIntervalSince1970: 100),
        )
    }

    func refreshSession(_: RefreshRequestDTO) async throws -> RefreshResponseDTO {
        calls.append(.refresh)
        return RefreshResponseDTO(
            accessToken: "new-access",
            accessExpiresAt: Date(timeIntervalSince1970: 200),
            replacementRefreshToken: nil,
        )
    }

    func revokeRefreshToken(_: String) async throws {
        calls.append(.revoke)
    }

    func recordedCalls() -> [Call] {
        calls
    }

    // MARK: Private

    private var calls = [Call]()

}
