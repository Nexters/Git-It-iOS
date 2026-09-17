import Foundation
import Testing
@testable import CompositionLearningProject
@testable import DataExternalRepository
@testable import DomainExternalRepository

struct ExternalRepositoryAssemblyTests {

    @Test
    func `live 그래프 생성이 성공하고 노출 property가 UseCase Protocol 타입이다`() throws {
        let assembly = ExternalRepositoryAssembly(baseURL: try #require(URL(string: "https://api.github.com")))

        _ = assembly.externalRepository as any ExternalRepositoryUseCase
        _ = assembly.locator as any ExternalRepositoryLocator
    }

}
