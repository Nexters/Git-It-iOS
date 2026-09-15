import Foundation
import InfrastructureStorage
import Testing

@testable import DataLearningProject

@Suite("LocalGenerationStateStore")
struct LocalGenerationStateStoreTests {

    @Test
    func `저장한 생성 상태를 그대로 다시 불러온다`() async {
        let store = LocalGenerationStateStore(store: Self.makeStore())
        let state = GenerationStateDTO(records: [Self.record(projectID: "p1")])

        await store.save(state)

        #expect(await store.load() == state)
    }

    @Test
    func `저장한 적이 없으면 빈 상태를 반환한다`() async {
        let store = LocalGenerationStateStore(store: Self.makeStore())
        #expect(await store.load().records.isEmpty)
    }

    @Test
    func `빈 상태를 저장하면 다음 불러오기도 빈 상태다`() async {
        let store = LocalGenerationStateStore(store: Self.makeStore())
        await store.save(GenerationStateDTO(records: [Self.record(projectID: "p1")]))
        await store.save(GenerationStateDTO(records: []))
        #expect(await store.load().records.isEmpty)
    }

    @Test
    func `앱을 다시 실행해도 저장한 생성 상태가 남아 있다`() async {
        let defaults = Self.makeDefaults()
        let state = GenerationStateDTO(records: [Self.record(projectID: "p1")])

        let first = LocalGenerationStateStore(store: Self.makeStore(defaults: defaults))
        await first.save(state)

        let relaunched = LocalGenerationStateStore(store: Self.makeStore(defaults: defaults))
        #expect(await relaunched.load() == state)
    }

    // MARK: Internal

    static func makeStore(defaults: UserDefaults? = nil) -> UserDefaultsStore<GenerationStateDTO> {
        UserDefaultsStore(namespace: "test.generationState", userDefaults: defaults ?? makeDefaults())
    }

    static func makeDefaults() -> UserDefaults {
        let suiteName = "test.generationState.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    static func record(
        projectID: String?,
        githubRepoURL: String = "https://github.com/owner/repo",
        requestedAt: Date = Date(timeIntervalSince1970: 1_000),
    ) -> GenerationRecordDTO {
        GenerationRecordDTO(
            githubRepoURL: githubRepoURL,
            projectID: projectID,
            requestedAt: requestedAt,
            status: "inProgress",
            finishedAt: nil,
        )
    }

}
