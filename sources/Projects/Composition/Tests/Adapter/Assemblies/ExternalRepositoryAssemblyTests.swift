import Foundation
import Testing
@testable import CompositionAdapter
@testable import DataExternalRepository
@testable import DomainLearningProject

struct ExternalRepositoryAssemblyTests {

    @Test
    func `live 그래프 생성이 성공하고 노출 property가 UseCase Protocol 타입이다`() throws {
        let assembly = ExternalRepositoryAssembly(baseURL: try #require(URL(string: "https://api.github.com")))

        _ = assembly.fetchExternalRepository as any FetchExternalRepositoryUseCase
    }

}
