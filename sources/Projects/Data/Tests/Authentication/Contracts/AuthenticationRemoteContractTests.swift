import Testing

@testable import DataAuthentication

@Suite("AuthenticationRemote 계약")
struct AuthenticationRemoteContractTests {

    @Test
    func `Apple 로그인과 Access Token 확인만 제공한다`() async throws {
        let remote = AuthenticationRemoteProbe()

        let response = try await remote.appleLogin(idToken: "apple-id-token")
        try await remote.verifyAccessToken()

        #expect(response.accessToken == "access")
        #expect(response.refreshToken == "refresh")
        #expect(!response.needsCuration)
        #expect(await remote.recordedCalls() == [.appleLogin, .verifyAccessToken])
    }

}

// MARK: - AuthenticationRemoteProbe

private actor AuthenticationRemoteProbe: AuthenticationRemote {

    // MARK: Internal

    enum Call: Equatable, Sendable { case appleLogin, verifyAccessToken }

    func appleLogin(idToken _: String) async throws -> LoginResponseDTO {
        calls.append(.appleLogin)
        return LoginResponseDTO(accessToken: "access", refreshToken: "refresh", needsCuration: false)
    }

    func verifyAccessToken() async throws {
        calls.append(.verifyAccessToken)
    }

    func recordedCalls() -> [Call] {
        calls
    }

    // MARK: Private

    private var calls = [Call]()

}
