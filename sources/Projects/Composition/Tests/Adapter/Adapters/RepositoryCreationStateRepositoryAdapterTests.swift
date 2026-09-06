import Foundation
import Synchronization
import Testing
@testable import CompositionAdapter
@testable import DomainLearningProject

// MARK: - RepositoryCreationStateRepositoryAdapterTests

@Suite("RepositoryCreationStateRepositoryAdapter")
struct RepositoryCreationStateRepositoryAdapterTests {

    // MARK: Internal

    @Test
    func `생성을 시작하고 projectID를 연결하면 활성 목록에 반영된다`() async throws {
        let adapter = RepositoryCreationStateRepositoryAdapter(userDefaults: try Self.makeUserDefaults())

        let began = await adapter.beginCreation(githubRepoURL: "https://github.com/owner/repo")
        await adapter.attachProjectID("project-1", toGithubRepoURL: "https://github.com/owner/repo")

        #expect(began == true)
        let activeProjectIDs = await adapter.activeProjectIDs()
        #expect(activeProjectIDs == ["project-1"])
    }

    @Test
    func `동일 정규화 URL에 대한 두 번째 시작은 거부되고 isCreating은 true를 유지한다`() async throws {
        let adapter = RepositoryCreationStateRepositoryAdapter(userDefaults: try Self.makeUserDefaults())

        _ = await adapter.beginCreation(githubRepoURL: "https://GitHub.com/owner/repo/")
        let secondBegan = await adapter.beginCreation(githubRepoURL: "https://github.com/owner/repo")

        #expect(secondBegan == false)
        let isCreating = await adapter.isCreating(githubRepoURL: " https://github.com/owner/repo ")
        #expect(isCreating == true)
    }

    @Test
    func `githubRepoURL로 해제하면 isCreating이 false로 돌아온다`() async throws {
        let adapter = RepositoryCreationStateRepositoryAdapter(userDefaults: try Self.makeUserDefaults())
        _ = await adapter.beginCreation(githubRepoURL: "https://github.com/owner/repo")

        await adapter.endCreation(githubRepoURL: "https://github.com/owner/repo")

        let isCreating = await adapter.isCreating(githubRepoURL: "https://github.com/owner/repo")
        #expect(isCreating == false)
    }

    @Test
    func `projectID로 해제하면 활성 목록에서 제거된다`() async throws {
        let adapter = RepositoryCreationStateRepositoryAdapter(userDefaults: try Self.makeUserDefaults())
        _ = await adapter.beginCreation(githubRepoURL: "https://github.com/owner/repo")
        await adapter.attachProjectID("project-1", toGithubRepoURL: "https://github.com/owner/repo")

        await adapter.endCreation(projectID: "project-1")

        let activeProjectIDs = await adapter.activeProjectIDs()
        #expect(activeProjectIDs.isEmpty)
        let isCreating = await adapter.isCreating(githubRepoURL: "https://github.com/owner/repo")
        #expect(isCreating == false)
    }

    @Test
    func `outcome 스트림에서 완료 신호를 받으면 생성 중 상태를 해제한다`() async throws {
        let adapter = RepositoryCreationStateRepositoryAdapter(userDefaults: try Self.makeUserDefaults())
        _ = await adapter.beginCreation(githubRepoURL: "https://github.com/owner/repo")
        await adapter.attachProjectID("project-1", toGithubRepoURL: "https://github.com/owner/repo")

        let outcomeSource = StubObserveGenerationOutcomesUseCase(outcomes: [
            GenerationOutcome(projectID: "project-1", status: .completed)
        ])
        await adapter.start(observeGenerationOutcomes: outcomeSource)

        var activeProjectIDs = await adapter.activeProjectIDs()
        var remainingAttempts = 50
        while !activeProjectIDs.isEmpty, remainingAttempts > 0 {
            await Task.yield()
            activeProjectIDs = await adapter.activeProjectIDs()
            remainingAttempts -= 1
        }

        #expect(activeProjectIDs.isEmpty)
    }

    @Test
    func `900초를 초과한 레코드는 다음 조회에서 만료된 것으로 취급한다`() async throws {
        let clockBox = ClockBox(current: Date(timeIntervalSince1970: 0))
        let adapter = RepositoryCreationStateRepositoryAdapter(
            userDefaults: try Self.makeUserDefaults(),
            clock: { clockBox.current },
        )
        _ = await adapter.beginCreation(githubRepoURL: "https://github.com/owner/repo")

        clockBox.current = clockBox.current.addingTimeInterval(901)
        let isCreating = await adapter.isCreating(githubRepoURL: "https://github.com/owner/repo")

        #expect(isCreating == false)
    }

    @Test
    func `App과 Share Extension처럼 서로 다른 인스턴스가 같은 저장소를 공유하면 중복 생성을 막는다`() async throws {
        let userDefaults = try Self.makeUserDefaults()
        let appAdapter = RepositoryCreationStateRepositoryAdapter(userDefaults: userDefaults)
        let shareExtensionAdapter = RepositoryCreationStateRepositoryAdapter(userDefaults: userDefaults)

        let began = await appAdapter.beginCreation(githubRepoURL: "https://github.com/owner/repo")
        let duplicateBegan = await shareExtensionAdapter.beginCreation(githubRepoURL: "https://github.com/owner/repo")

        #expect(began == true)
        #expect(duplicateBegan == false)
        let isCreatingFromOtherInstance = await shareExtensionAdapter.isCreating(
            githubRepoURL: "https://github.com/owner/repo"
        )
        #expect(isCreatingFromOtherInstance == true)
    }

    // MARK: Private

    private static func makeUserDefaults() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: "RepositoryCreationStateRepositoryAdapterTests.\(UUID().uuidString)"))
    }

}

// MARK: - ClockBox

private final class ClockBox: Sendable {

    // MARK: Lifecycle

    init(current: Date) {
        storage = Mutex(current)
    }

    // MARK: Internal

    var current: Date {
        get {
            storage.withLock { $0 }
        }
        set {
            storage.withLock { $0 = newValue }
        }
    }

    // MARK: Private

    private let storage: Mutex<Date>

}

// MARK: - StubObserveGenerationOutcomesUseCase

private struct StubObserveGenerationOutcomesUseCase: ObserveGenerationOutcomesUseCase {

    let outcomes: [GenerationOutcome]

    func callAsFunction() async -> AsyncStream<GenerationOutcome> {
        AsyncStream { continuation in
            for outcome in outcomes {
                continuation.yield(outcome)
            }
            continuation.finish()
        }
    }

}
