import Foundation
import InfrastructureAuthentication
import Testing

@testable import DataAuthentication

// MARK: - AppleSignInSourceTests

@Suite("AppleSignInSource")
struct AppleSignInSourceTests {

    // MARK: Internal

    @Test
    func `인증 결과의 사용자 식별자와 identity token을 돌려준다`() async throws {
        let source = makeSource(authorize: {
            Self.makeCredential(identityToken: Data("id-token-1".utf8))
        })

        let credential = try await source.authorize()

        #expect(credential == AppleSignInCredential(userID: "apple-user-1", identityToken: "id-token-1"))
    }

    @Test
    func `identity token이 없으면 unavailable 오류를 던진다`() async {
        let source = makeSource(authorize: {
            Self.makeCredential(identityToken: nil)
        })

        await #expect(throws: AppleSignInError.unavailable) {
            try await source.authorize()
        }
    }

    @Test
    func `사용자가 인증을 취소하면 cancelled 오류로 변환한다`() async {
        let source = makeSource(authorize: {
            throw AppleAuthorizationError.cancelled
        })

        await #expect(throws: AppleSignInError.cancelled) {
            try await source.authorize()
        }
    }

    @Test(arguments: [
        AppleAuthorizationError.invalidCallback,
        .expiredAttempt,
        .missingCredential,
        .unavailable,
    ])
    func `취소 외 인증 오류는 unavailable 오류로 변환한다`(error: AppleAuthorizationError) async {
        let source = makeSource(authorize: {
            throw error
        })

        await #expect(throws: AppleSignInError.unavailable) {
            try await source.authorize()
        }
    }

    @Test(arguments: [
        (AppleCredentialState.authorized, AppleSignInState.authorized),
        (.revoked, .reauthenticationRequired),
        (.notFound, .reauthenticationRequired),
        (.transferred, .reauthenticationRequired),
        (.temporarilyUnavailable, .temporarilyUnavailable),
    ])
    func `자격 상태를 로그인 상태로 변환한다`(
        credentialState: AppleCredentialState,
        expected: AppleSignInState,
    ) async {
        let source = AppleSignInSource(
            authorize: { Self.makeCredential(identityToken: nil) },
            credentialState: { _ in credentialState },
        )

        let state = await source.state(forUserID: "apple-user-1")

        #expect(state == expected)
    }

    // MARK: Private

    private static func makeCredential(identityToken: Data?) -> AppleCredential {
        AppleCredential(
            userID: "apple-user-1",
            identityToken: identityToken,
            authorizationCode: Data("code-1".utf8),
            email: nil,
            fullName: nil,
        )
    }

    private func makeSource(
        authorize: @escaping @Sendable () async throws -> AppleCredential
    ) -> AppleSignInSource {
        AppleSignInSource(
            authorize: authorize,
            credentialState: { _ in .authorized },
        )
    }

}
