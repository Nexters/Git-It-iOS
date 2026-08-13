import Testing

@testable import DataAuthentication

// MARK: - AuthenticationProviderContractTests

@Suite("AuthenticationProvider 계약")
struct AuthenticationProviderContractTests {
    @Test
    func `인증과 authorization 조회 및 변경만 제공한다`() async throws {
        let provider = AuthenticationProviderProbe()
        let evidence = try await provider.authenticate(methodIdentifier: "social-provider")
        let state = try await provider.authorizationState(
            methodIdentifier: "social-provider",
            subjectReference: "subject-reference",
        )
        let changes = await provider.authorizationChanges(
            methodIdentifier: "social-provider",
            subjectReference: "subject-reference",
        )
        var iterator = changes.makeAsyncIterator()

        #expect(evidence.methodIdentifier == "social-provider")
        #expect(state == .active)
        #expect(await iterator.next() == .inactive)
    }
}

// MARK: - AuthenticationProviderProbe

private struct AuthenticationProviderProbe: AuthenticationProvider {
    func authenticate(methodIdentifier: String) async throws -> AuthenticationEvidence {
        AuthenticationEvidence(
            methodIdentifier: methodIdentifier,
            providerSubjectReference: "subject-reference",
            opaquePayload: .init(bytes: [1]),
        )
    }

    func authorizationState(
        methodIdentifier _: String,
        subjectReference _: String,
    ) async throws -> AuthorizationState {
        .active
    }

    func authorizationChanges(
        methodIdentifier _: String,
        subjectReference _: String,
    ) async -> AsyncStream<AuthorizationState> {
        AsyncStream { continuation in
            continuation.yield(.inactive)
            continuation.finish()
        }
    }
}
