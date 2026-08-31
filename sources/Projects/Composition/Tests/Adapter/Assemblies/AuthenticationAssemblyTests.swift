import Foundation
import Testing
@testable import CompositionAdapter
@testable import DataAuthentication
@testable import DomainAuthentication
@testable import InfrastructureAuthentication

struct AuthenticationAssemblyTests {

    @Test
    func `live 그래프 생성이 성공하고 노출 property가 모두 UseCase Protocol 타입이다`() throws {
        let assembly = AuthenticationAssembly(baseURL: try #require(URL(string: "https://api.git-it.example.com")))

        _ = assembly.signIn as any SignInUseCase
        _ = assembly.signOut as any SignOutUseCase
        _ = assembly.restoreSession as any RestoreSessionUseCase
        _ = assembly.authenticationOutcomes as any AuthenticationOutcomesUseCase
        _ = assembly.refreshSession as any RefreshSessionUseCase
        _ = assembly.verifyAccessToken as any VerifyAccessTokenUseCase
    }

    @Test
    func `저장된 세션이 없으면 restoreSession이 RestoreSessionResult unauthenticated를 반환한다`() async throws {
        let assembly = AuthenticationAssembly(
            baseURL: try #require(URL(string: "https://api.git-it.example.com")),
            keychainStore: KeychainStore(backend: KeychainStore.InMemoryBackend()),
        )

        let result = await assembly.restoreSession()

        #expect(result == .unauthenticated)
    }

    @Test
    func `저장된 세션이 없어도 signOut은 SignOutResult success를 반환한다`() async throws {
        let assembly = AuthenticationAssembly(
            baseURL: try #require(URL(string: "https://api.git-it.example.com")),
            keychainStore: KeychainStore(backend: KeychainStore.InMemoryBackend()),
        )

        let result = await assembly.signOut()

        #expect(result == .success)
    }

}
