import DomainIdentifier
import DomainProject
import Foundation

actor HomeLearningProjectsUseCaseMock: ProjectUseCase {

    // MARK: Lifecycle

    init(
        initialList: ProjectList = ProjectList(summaries: [], hasNextPage: false, isLoaded: false),
        refreshResults: [Result<Void, ProjectError>] = [.success(())],
        nextPageResults: [Result<Void, ProjectError>] = [.success(())],
        detailResults: [Result<ProjectDetail, ProjectError>] = [.failure(.notFound)],
        suspendsRefresh: Bool = false,
    ) {
        currentList = initialList
        self.refreshResults = refreshResults
        self.nextPageResults = nextPageResults
        self.detailResults = detailResults
        self.suspendsRefresh = suspendsRefresh
    }

    // MARK: Internal

    private(set) var deletedProjectIDs = [ProjectID]()

    func projects() async -> AsyncStream<ProjectList> {
        let (stream, continuation) = AsyncStream<ProjectList>.makeStream()
        let subscriberID = UUID()
        continuations[subscriberID] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(subscriberID) }
        }
        continuation.yield(currentList)
        return stream
    }

    func refresh() async throws {
        refreshCallCount += 1
        let result = nextRefreshResult()
        guard suspendsRefresh else { return try result.get() }

        return try await withCheckedThrowingContinuation { continuation in
            refreshContinuations.append((continuation, result))
        }
    }

    func requestNextPage() async throws {
        nextPageCallCount += 1
        guard !nextPageResults.isEmpty else { return }
        let result = nextPageResults.count > 1 ? nextPageResults.removeFirst() : nextPageResults[0]
        try result.get()
    }

    func detail(of projectID: ProjectID) async throws -> ProjectDetail {
        requestedDetailProjectIDs.append(projectID)
        guard !detailResults.isEmpty else { throw ProjectError.notFound }
        let result = detailResults.count > 1 ? detailResults.removeFirst() : detailResults[0]
        return try result.get()
    }

    func delete(_ projectID: ProjectID) async throws {
        deletedProjectIDs.append(projectID)
    }

    func snapshot() -> (refreshCallCount: Int, nextPageCallCount: Int, pendingCount: Int) {
        (refreshCallCount, nextPageCallCount, refreshContinuations.count)
    }

    func activeSubscriptionCount() -> Int {
        continuations.count
    }

    func emit(_ list: ProjectList) {
        currentList = list
        for continuation in continuations.values {
            continuation.yield(list)
        }
    }

    func finish() {
        for continuation in continuations.values {
            continuation.finish()
        }
        continuations.removeAll()
    }

    func resumeNext() {
        guard !refreshContinuations.isEmpty else { return }
        let (continuation, result) = refreshContinuations.removeFirst()
        continuation.resume(with: result)
    }

    // MARK: Private

    private var currentList: ProjectList
    private var refreshResults: [Result<Void, ProjectError>]
    private var nextPageResults: [Result<Void, ProjectError>]
    private var detailResults: [Result<ProjectDetail, ProjectError>]
    private let suspendsRefresh: Bool
    private var refreshCallCount = 0
    private var nextPageCallCount = 0
    private var requestedDetailProjectIDs = [ProjectID]()
    private var continuations = [UUID: AsyncStream<ProjectList>.Continuation]()
    private var refreshContinuations = [(
        CheckedContinuation<Void, any Error>,
        Result<Void, ProjectError>,
    )]()

    private func removeSubscriber(_ subscriberID: UUID) {
        continuations.removeValue(forKey: subscriberID)
    }

    private func nextRefreshResult() -> Result<Void, ProjectError> {
        guard !refreshResults.isEmpty else { return .success(()) }
        return refreshResults.count > 1 ? refreshResults.removeFirst() : refreshResults[0]
    }

}
