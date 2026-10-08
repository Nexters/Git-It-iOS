import DataShared
import Foundation
import Testing
@testable import CompositionLearningProject
@testable import DataLearningProject
@testable import DomainUseCaseInterface

struct LearningProjectAssemblyTests {

    // MARK: Internal

    @Test
    func `live 그래프 생성이 성공하고 노출 property가 UseCase Protocol 타입이다`() throws {
        let assembly = try Self.makeAssembly()

        _ = assembly.projectGeneration as any ProjectGenerationUseCase
    }

    @Test
    func `요청이 없으면 생성 상태에 진행 중 기록이 없다`() async throws {
        let assembly = try Self.makeAssembly()

        var iterator = await assembly.projectGeneration.states().makeAsyncIterator()
        let state = await iterator.next()

        #expect(state?.requests.isEmpty == true)
    }

    // MARK: Private

    private static func makeAssembly() throws -> LearningProjectAssembly {
        LearningProjectAssembly(
            baseURL: try #require(URL(string: "https://api.git-it.example.com")),
            credential: { .signedOut },
            credentialRejected: { },
            sharedStorage: InMemoryKeyValueStorage(),
        )
    }

}
