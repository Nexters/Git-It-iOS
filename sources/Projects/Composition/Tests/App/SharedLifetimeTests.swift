import Foundation
import Testing

@testable import CompositionAuthentication
@testable import DataAuthentication
@testable import DataShared
@testable import DomainAccount

// MARK: - SharedLifetimeTests

@Suite("공유 수명 객체", .serialized)
struct SharedLifetimeTests {

    // MARK: Internal

    @Test
    func `같은 보안 저장소를 공유해도 Authentication과 SignIn의 저장 값이 서로 섞이지 않는다`() async throws {
        let sharedSecureStorage = InMemorySecureValueStorage()
        let authenticationRepository = AuthenticationRepositoryAdapter(
            appleSignInSource: AppleSignInSource(),
            secureStorage: sharedSecureStorage,
        )
        let signInRepository = SignInRepositoryAdapter(
            remote: makeRemote(transport: RecordingRequestTransport(results: [])),
            sessionStorage: sharedSecureStorage,
            appleIdentityStorage: sharedSecureStorage,
            requestCredentialProvider: RequestCredentialProvider(secureStorage: sharedSecureStorage),
            sharedSessionStateMarkerCoding: nil,
        )

        try await authenticationRepository.clearAuthentication()
        try await signInRepository.signOut()

        let restoredBeforeSignIn = try await signInRepository.restore()
        let statusBeforeSignIn = try await authenticationRepository.authorizationStatus()

        #expect(restoredBeforeSignIn == nil)
        #expect(statusBeforeSignIn == .reauthenticationRequired)

        try await authenticationRepository.clearAuthentication()
        try await signInRepository.signOut()
    }

    // MARK: Private

    private func makeRemote(transport: RecordingRequestTransport) -> AuthenticationRemote {
        AuthenticationRemote(
            baseURL: URL(string: "https://api.git-it.example.com")!,
            transport: transport,
            responseTimeout: RequestClientFactory.defaultResponseTimeout,
            credential: { .signedOut },
        )
    }

}
