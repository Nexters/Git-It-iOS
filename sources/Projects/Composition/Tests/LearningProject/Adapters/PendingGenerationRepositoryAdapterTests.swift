import DataShared
import Foundation
import Synchronization
import Testing
@testable import CompositionLearningProject
@testable import DataLearningProject
@testable import DomainProjectGeneration

// MARK: - PendingGenerationRepositoryAdapterTests

@Suite("PendingGenerationRepositoryAdapter")
struct PendingGenerationRepositoryAdapterTests {

    // MARK: Internal

    @Test
    func `같은 저장소를 공유하면 한쪽의 생성 기록을 다른 쪽이 조회한다`() async {
        let storage = InMemoryKeyValueStorage()
        let shareExtension = Self.makeAdapter(storage: storage)
        let app = Self.makeAdapter(storage: storage)

        #expect(await shareExtension.beginGeneration(
            repositoryURL: Self.url,
            requestedAt: Self.requestedAt,
        ))
        await shareExtension.attachProjectID(
            "project-1",
            toRepositoryURL: Self.url,
        )

        let state = await app.pendingState()
        #expect(state.isCreating(repositoryURL: Self.url))
        #expect(state.record(repositoryURL: Self.url)?.projectID == "project-1")
    }

    @Test
    func `같은 저장소를 공유하면 한쪽이 남긴 알림 대기를 다른 쪽이 흡수한다`() async {
        let storage = InMemoryKeyValueStorage()
        let shareExtension = Self.makeAdapter(storage: storage)
        let app = Self.makeAdapter(storage: storage)

        await shareExtension.enqueueReminder(projectID: "project-1")

        #expect(await app.drainReminderProjectIDs() == ["project-1"])
        #expect(await shareExtension.drainReminderProjectIDs().isEmpty)
    }

    @Test
    func `같은 URL로 동시에 생성을 시작하면 하나만 성공한다`() async {
        let adapter = Self.makeAdapter(storage: InMemoryKeyValueStorage())

        let results = await withTaskGroup(of: Bool.self) { group in
            for _ in 0 ..< 10 {
                group.addTask {
                    await adapter.beginGeneration(
                        repositoryURL: Self.url,
                        requestedAt: Self.requestedAt,
                    )
                }
            }
            return await group.reduce(into: [Bool]()) { $0.append($1) }
        }

        #expect(results.count(where: { $0 }) == 1)
    }

    @Test
    func `보존 기간이 지난 기록을 정리한 뒤 같은 URL로 다시 시작할 수 있다`() async {
        let clock = Clock(now: Self.requestedAt)
        let adapter = Self.makeAdapter(
            storage: InMemoryKeyValueStorage(),
            now: { clock.current() },
        )
        _ = await adapter.beginGeneration(
            repositoryURL: Self.url,
            requestedAt: Self.requestedAt,
        )

        clock.advance(to: Self.requestedAt.addingTimeInterval(Self.retentionLimit + 1))

        #expect(await adapter.pendingState().records.isEmpty)
        #expect(await adapter.beginGeneration(
            repositoryURL: Self.url,
            requestedAt: clock.current(),
        ))
    }

    @Test
    func `확인된 대기 상태는 저장 기록을 Domain 모델로 바꾸고 보존 기간이 지난 기록을 뺀다`() async throws {
        let clock = Clock(now: Self.requestedAt)
        let adapter = Self.makeAdapter(
            storage: InMemoryKeyValueStorage(),
            now: { clock.current() },
        )
        _ = await adapter.beginGeneration(
            repositoryURL: Self.url,
            requestedAt: Self.requestedAt,
        )
        await adapter.attachProjectID(
            "project-1",
            toRepositoryURL: Self.url,
        )

        let current = try await adapter.confirmedPendingState()
        clock.advance(to: Self.requestedAt.addingTimeInterval(Self.retentionLimit + 1))
        let expired = try await adapter.confirmedPendingState()

        #expect(current.record(projectID: "project-1")?.status == .inProgress)
        #expect(expired.records.isEmpty)
    }

    @Test(arguments: [KeyValueStorageError.unavailable, .unreadable])
    func `확인된 대기 상태 조회는 저장소 판독 실패를 stateUnavailable로 바꿔 던진다`(failure: KeyValueStorageError) async {
        let adapter = Self.makeAdapter(storage: InMemoryKeyValueStorage(verificationFailure: failure))

        await #expect(throws: ProjectGenerationError.stateUnavailable) {
            try await adapter.confirmedPendingState()
        }
    }

    @Test
    func `상태 변화 스트림은 저장 값을 Domain 모델로 바꿔 전달한다`() async {
        let adapter = Self.makeAdapter(storage: InMemoryKeyValueStorage())
        _ = await adapter.beginGeneration(
            repositoryURL: Self.url,
            requestedAt: Self.requestedAt,
        )
        await adapter.attachProjectID(
            "project-1",
            toRepositoryURL: Self.url,
        )

        var iterator = await adapter.pendingStateChanges().makeAsyncIterator()
        let first = await iterator.next()
        _ = await adapter.finishGeneration(
            projectID: "project-1",
            status: .completed,
            finishedAt: Self.requestedAt,
        )
        let second = await iterator.next()

        #expect(first?.record(projectID: "project-1")?.status == .inProgress)
        #expect(second?.record(projectID: "project-1")?.status == .completed)
    }

    @Test
    func `기록이 있는 프로젝트의 결과 반영은 true를 돌려준다`() async {
        let adapter = Self.makeAdapter(storage: InMemoryKeyValueStorage())
        _ = await adapter.beginGeneration(
            repositoryURL: Self.url,
            requestedAt: Self.requestedAt,
        )
        await adapter.attachProjectID(
            "project-1",
            toRepositoryURL: Self.url,
        )

        let isRecorded = await adapter.finishGeneration(
            projectID: "project-1",
            status: .completed,
            finishedAt: Self.requestedAt,
        )

        #expect(isRecorded)
        #expect(await adapter.pendingState().record(projectID: "project-1")?.status == .completed)
    }

    @Test
    func `기록이 없는 프로젝트의 결과 반영은 false를 돌려주고 저장소를 바꾸지 않는다`() async {
        let storage = InMemoryKeyValueStorage()
        let adapter = Self.makeAdapter(storage: storage)
        _ = await adapter.beginGeneration(
            repositoryURL: Self.url,
            requestedAt: Self.requestedAt,
        )
        let before = await adapter.pendingState()

        let isRecorded = await adapter.finishGeneration(
            projectID: "project-unknown",
            status: .completed,
            finishedAt: Self.requestedAt,
        )

        #expect(!isRecorded)
        #expect(await adapter.pendingState() == before)
    }

    // MARK: Private

    private final class Clock: Sendable {

        // MARK: Lifecycle

        init(now: Date) {
            date = Mutex(now)
        }

        // MARK: Internal

        func current() -> Date {
            date.withLock { $0 }
        }

        func advance(to next: Date) {
            date.withLock { $0 = next }
        }

        // MARK: Private

        private let date: Mutex<Date>

    }

    private static let url = "https://github.com/owner/repo"
    private static let requestedAt = Date(timeIntervalSince1970: 1_000)
    private static let retentionLimit: TimeInterval = 3_600

    private static func makeAdapter(
        storage: InMemoryKeyValueStorage,
        now: @escaping @Sendable () -> Date = { requestedAt },
    ) -> PendingGenerationRepositoryAdapter {
        PendingGenerationRepositoryAdapter(
            store: LocalPendingGenerationStore(storage: storage),
            waitPolicy: GenerationWaitPolicy(
                retentionLimit: retentionLimit,
                reminderValidity: 300,
            ),
            now: now,
        )
    }

}
