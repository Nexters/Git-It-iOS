import Foundation
import Testing

@testable import DataLearningProject
@testable import DataShared

// MARK: - LocalPendingGenerationStoreTests

@Suite("LocalPendingGenerationStore")
struct LocalPendingGenerationStoreTests {

    // MARK: Internal

    @Test
    func `저장한 적이 없으면 빈 생성 상태를 돌려준다`() async {
        let store = LocalPendingGenerationStore(storage: InMemoryKeyValueStorage())

        #expect(await store.state().records.isEmpty)
    }

    @Test
    func `확인 조회는 저장한 적이 없으면 빈 생성 상태를 돌려준다`() async throws {
        let store = LocalPendingGenerationStore(storage: InMemoryKeyValueStorage())

        let state = try await store.verifiedState()

        #expect(state.records.isEmpty)
    }

    @Test
    func `확인 조회는 기록된 생성 상태를 돌려준다`() async throws {
        let store = LocalPendingGenerationStore(storage: InMemoryKeyValueStorage())
        let state = GenerationStateDTO(records: [Self.record(projectID: "p1")])
        await store.modifyState { _ in state }

        let verified = try await store.verifiedState()

        #expect(verified == state)
    }

    @Test(arguments: [KeyValueStorageError.unavailable, .unreadable])
    func `확인 조회는 저장소의 판독 실패를 그대로 전파한다`(failure: KeyValueStorageError) async {
        let store = LocalPendingGenerationStore(storage: InMemoryKeyValueStorage(verificationFailure: failure))

        await #expect(throws: failure) {
            try await store.verifiedState()
        }
    }

    @Test
    func `변환 결과를 기록하고 같은 저장소의 다른 인스턴스가 그 상태를 읽는다`() async {
        let storage = InMemoryKeyValueStorage()
        let store = LocalPendingGenerationStore(storage: storage)
        let state = GenerationStateDTO(records: [Self.record(projectID: "p1")])

        let written = await store.modifyState { _ in state }

        #expect(written == state)
        #expect(await LocalPendingGenerationStore(storage: storage).state() == state)
        #expect(storage.storedData(forKey: "generationState") != nil)
    }

    @Test
    func `변환이 nil을 돌려주면 기록하지 않는다`() async {
        let storage = InMemoryKeyValueStorage()
        let store = LocalPendingGenerationStore(storage: storage)

        let written = await store.modifyState { _ in nil }

        #expect(written == nil)
        #expect(storage.storedData(forKey: "generationState") == nil)
    }

    @Test
    func `구독하면 현재 상태를 먼저 받고 기록할 때마다 새 상태를 받는다`() async {
        let store = LocalPendingGenerationStore(storage: InMemoryKeyValueStorage())
        let next = GenerationStateDTO(records: [Self.record(projectID: "p1")])

        var iterator = await store.stateChanges().makeAsyncIterator()
        let first = await iterator.next()
        await store.modifyState { _ in next }
        let second = await iterator.next()

        #expect(first == GenerationStateDTO(records: []))
        #expect(second == next)
    }

    @Test
    func `구독을 끝내면 이후 기록을 전달하지 않는다`() async {
        let store = LocalPendingGenerationStore(storage: InMemoryKeyValueStorage())
        let stream = await store.stateChanges()
        let task = Task {
            var received = [GenerationStateDTO]()
            for await state in stream {
                received.append(state)
            }
            return received
        }

        task.cancel()
        let received = await task.value
        await store.modifyState { _ in GenerationStateDTO(records: [Self.record(projectID: "p1")]) }

        #expect(received.allSatisfy { $0.records.isEmpty })
    }

    @Test
    func `저장소를 사용할 수 없으면 기록해도 빈 상태를 돌려준다`() async {
        let store = LocalPendingGenerationStore(
            storage: StorageFactory.keyValueStorage(store: nil)
        )

        await store.modifyState { _ in GenerationStateDTO(records: [Self.record(projectID: "p1")]) }

        #expect(await store.state().records.isEmpty)
    }

    // MARK: Private

    private static let requestedAt = Date(timeIntervalSince1970: 1_000)

    private static func record(projectID: String) -> GenerationRecordDTO {
        GenerationRecordDTO(
            githubRepoURL: "https://github.com/owner/repo",
            projectID: projectID,
            requestedAt: requestedAt,
            status: "inProgress",
            finishedAt: nil,
        )
    }

}
