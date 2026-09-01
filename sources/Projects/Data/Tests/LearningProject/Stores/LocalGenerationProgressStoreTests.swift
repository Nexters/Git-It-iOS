import Foundation
import InfrastructureStorage
import Testing

@testable import DataLearningProject

@Suite("LocalGenerationProgressStore")
struct LocalGenerationProgressStoreTests {

    // MARK: Internal

    @Test
    func `저장한 진행 상태를 그대로 조회한다`() async {
        let (store, _) = makeStore()
        let progress = GenerationProgressDTO(projectID: "project-1", requestedAt: Date(timeIntervalSince1970: 1_000))

        await store.save(progress)

        #expect(await store.load() == progress)
    }

    @Test
    func `기록한 적이 없으면 nil을 반환한다`() async {
        let (store, _) = makeStore()

        #expect(await store.load() == nil)
    }

    @Test
    func `다시 저장하면 이전 기록을 대체해 1건만 남는다`() async {
        let (store, _) = makeStore()
        await store.save(GenerationProgressDTO(projectID: "project-1", requestedAt: Date(timeIntervalSince1970: 1_000)))

        let latest = GenerationProgressDTO(projectID: "project-2", requestedAt: Date(timeIntervalSince1970: 2_000))
        await store.save(latest)

        #expect(await store.load() == latest)
    }

    @Test
    func `해제하면 조회 결과가 부재로 돌아간다`() async {
        let (store, _) = makeStore()
        await store.save(GenerationProgressDTO(projectID: "project-1", requestedAt: Date(timeIntervalSince1970: 1_000)))

        await store.clear()

        #expect(await store.load() == nil)
    }

    @Test
    func `앱을 다시 실행해도 저장한 진행 상태가 남아 있다`() async throws {
        let suiteName = "generation-progress-\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let progress = GenerationProgressDTO(projectID: "project-1", requestedAt: Date(timeIntervalSince1970: 1_000))
        let store = LocalGenerationProgressStore(store: UserDefaultsStore(
            namespace: Self.namespace,
            userDefaults: userDefaults,
        ))
        await store.save(progress)

        let afterRelaunch = LocalGenerationProgressStore(store: UserDefaultsStore(
            namespace: Self.namespace,
            userDefaults: userDefaults,
        ))

        #expect(await afterRelaunch.load() == progress)
    }

    // MARK: Private

    private static let namespace = "learning-project-generation-progress"

    private func makeStore() -> (LocalGenerationProgressStore, UserDefaults) {
        let suiteName = "generation-progress-\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        return (
            LocalGenerationProgressStore(store: UserDefaultsStore(
                namespace: Self.namespace,
                userDefaults: userDefaults,
            )),
            userDefaults,
        )
    }

}
