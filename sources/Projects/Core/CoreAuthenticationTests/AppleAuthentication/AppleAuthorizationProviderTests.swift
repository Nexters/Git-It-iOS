import Foundation
import Testing

@testable import CoreAuthentication

@Suite("AppleAuthorizationProvider")
struct AppleAuthorizationProviderTests {
    @Test
    func `명시적으로 시작한 시도만 유효한 credential을 반환한다`() throws {
        let provider = AppleAuthorizationProvider(
            randomValue: { String(
                repeating: "x",
                count: $0,
            ) },
            now: { Date(timeIntervalSince1970: 10) },
        )
        let attempt = try provider.beginAuthorization(expiresIn: 30)
        let credential = AppleCredential(
            userID: "user",
            identityToken: Data([1]),
            authorizationCode: Data([2]),
            email: nil,
            fullName: nil,
        )

        #expect(try provider.complete(
            credential: credential,
            state: attempt.state,
            attemptID: attempt.id,
        ) == credential)
        #expect(credential.requestedScopes == [.email, .fullName])
    }

    @Test
    func `취소와 불일치 또는 만료 및 누락 credential을 격리한다`() throws {
        let now = Date(timeIntervalSince1970: 10)
        let cancelledProvider = AppleAuthorizationProvider(
            randomValue: { String(
                repeating: "x",
                count: $0,
            ) },
            now: { now },
        )
        let cancelledAttempt = try cancelledProvider.beginAuthorization(expiresIn: 1)
        let credential = AppleCredential(
            userID: "user",
            identityToken: nil,
            authorizationCode: Data([2]),
            email: nil,
            fullName: nil,
        )

        #expect(throws: AppleAuthorizationError.cancelled) { try cancelledProvider.cancel(attemptID: cancelledAttempt.id) }
        let invalidProvider = AppleAuthorizationProvider(
            randomValue: { String(
                repeating: "x",
                count: $0,
            ) },
            now: { now },
        )
        let invalidAttempt = try invalidProvider.beginAuthorization(expiresIn: 1)
        #expect(throws: AppleAuthorizationError.invalidCallback) {
            try invalidProvider.complete(
                credential: credential,
                state: "other",
                attemptID: invalidAttempt.id,
            )
        }
        let missingProvider = AppleAuthorizationProvider(
            randomValue: { String(
                repeating: "x",
                count: $0,
            ) },
            now: { now },
        )
        let missingAttempt = try missingProvider.beginAuthorization(expiresIn: 1)
        #expect(throws: AppleAuthorizationError.missingCredential) {
            try missingProvider.complete(
                credential: credential,
                state: missingAttempt.state,
                attemptID: missingAttempt.id,
            )
        }
        let expiredProvider = AppleAuthorizationProvider(
            randomValue: { String(
                repeating: "x",
                count: $0,
            ) },
            now: { now },
        )
        let expiredAttempt = try expiredProvider.beginAuthorization(expiresIn: 1)
        #expect(throws: AppleAuthorizationError.expiredAttempt) {
            try expiredProvider.complete(
                credential: credential,
                state: expiredAttempt.state,
                attemptID: expiredAttempt.id,
                now: now.addingTimeInterval(2),
            )
        }
    }
}
