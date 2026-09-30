import DomainIdentifier
import Foundation

public actor Project: ProjectUseCase {

    // MARK: Lifecycle

    public init(
        repository: any ProjectRepository,
        signedOutEvents: @escaping @Sendable () async -> AsyncStream<Void>,
        projectDeleted: @escaping @Sendable (ProjectID) async -> Void,
        projectsListed: @escaping @Sendable ([ProjectID]) async -> Void,
        pageSize: Int = 20,
    ) {
        self.repository = repository
        self.signedOutEvents = signedOutEvents
        self.projectDeleted = projectDeleted
        self.projectsListed = projectsListed
        self.pageSize = pageSize
    }

    // MARK: Public

    public func projects() async -> AsyncStream<ProjectList> {
        startObserving()
        let (stream, continuation) = AsyncStream<ProjectList>.makeStream()
        let subscriberID = UUID()
        subscribers[subscriberID] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(subscriberID) }
        }
        continuation.yield(currentList)
        if !isLoaded, firstPageTask == nil {
            Task { try? await self.requestFirstPage() }
        }
        return stream
    }

    public func refresh() async throws {
        startObserving()
        try await requestFirstPage()
    }

    public func refreshReplacingInFlightRequest() async throws {
        startObserving()
        epoch += 1
        firstPageTask?.cancel()
        firstPageTask = nil
        nextPageTask?.cancel()
        nextPageTask = nil
        try await requestFirstPage()
    }

    public func requestNextPage() async throws {
        startObserving()
        if let nextPageTask {
            try await awaitNextPage(
                nextPageTask,
                epoch: epoch,
            )
            return
        }
        guard hasNextPage else { return }
        let repository = repository
        let index = nextPageIndex
        let size = pageSize
        let epoch = epoch
        let task = Task<Void, Error> {
            let page = try await repository.page(
                index,
                size: size,
            )
            guard
                self.appendPage(
                    page,
                    epoch: epoch,
                )
            else { return }
            await self.projectsListed(page.summaries.map(\.id))
        }
        nextPageTask = task
        defer { clearNextPageTask(epoch: epoch) }
        try await awaitNextPage(
            task,
            epoch: epoch,
        )
    }

    public func detail(of projectID: ProjectID) async throws -> ProjectDetail {
        startObserving()
        return try await repository.detail(of: projectID)
    }

    public func delete(_ projectID: ProjectID) async throws {
        startObserving()
        try await repository.delete(projectID)
        loaded.removeAll { $0.id == projectID }
        emit()
        await projectDeleted(projectID)
    }

    // MARK: Private

    private let repository: any ProjectRepository
    private let signedOutEvents: @Sendable () async -> AsyncStream<Void>
    private let projectDeleted: @Sendable (ProjectID) async -> Void
    private let projectsListed: @Sendable ([ProjectID]) async -> Void
    private let pageSize: Int

    private var loaded = [ProjectSummary]()
    private var nextPageIndex = 0
    private var hasNextPage = false
    private var isLoaded = false
    private var epoch = 0
    private var resetEpoch = 0
    private var firstPageTask: Task<Void, Error>?
    private var nextPageTask: Task<Void, Error>?
    private var subscribers = [UUID: AsyncStream<ProjectList>.Continuation]()
    private var observationTasks = [Task<Void, Never>]()

    private var currentList: ProjectList {
        ProjectList(
            summaries: loaded,
            hasNextPage: hasNextPage,
            isLoaded: isLoaded,
        )
    }

    private func startObserving() {
        guard observationTasks.isEmpty else { return }
        let signedOutEvents = signedOutEvents
        observationTasks = [
            Task { [weak self] in
                for await _ in await signedOutEvents() {
                    await self?.reset()
                }
            }
        ]
    }

    private func requestFirstPage() async throws {
        if let firstPageTask {
            try await awaitFirstPage(
                firstPageTask,
                epoch: epoch,
            )
            return
        }
        let repository = repository
        let size = pageSize
        let epoch = epoch
        let task = Task<Void, Error> {
            let page = try await repository.page(
                0,
                size: size,
            )
            guard
                self.replaceWithFirstPage(
                    page,
                    epoch: epoch,
                )
            else { return }
            await self.projectsListed(page.summaries.map(\.id))
        }
        firstPageTask = task
        defer { clearFirstPageTask(epoch: epoch) }
        try await awaitFirstPage(
            task,
            epoch: epoch,
        )
    }

    private func awaitFirstPage(
        _ task: Task<Void, Error>,
        epoch requestEpoch: Int,
    ) async throws {
        do {
            try await task.value
        } catch {
            guard isReplaced(requestEpoch) else { throw error }
        }
        guard isReplaced(requestEpoch), let firstPageTask else { return }
        try await awaitFirstPage(
            firstPageTask,
            epoch: epoch,
        )
    }

    private func awaitNextPage(
        _ task: Task<Void, Error>,
        epoch requestEpoch: Int,
    ) async throws {
        do {
            try await task.value
        } catch {
            guard isReplaced(requestEpoch) else { throw error }
        }
    }

    private func isReplaced(_ requestEpoch: Int) -> Bool {
        requestEpoch != epoch && resetEpoch <= requestEpoch
    }

    private func replaceWithFirstPage(
        _ page: ProjectPage,
        epoch: Int,
    ) -> Bool {
        guard epoch == self.epoch else { return false }
        loaded = page.summaries
        nextPageIndex = 1
        hasNextPage = page.hasNextPage
        isLoaded = true
        emit()
        return true
    }

    private func appendPage(
        _ page: ProjectPage,
        epoch: Int,
    ) -> Bool {
        guard epoch == self.epoch else { return false }
        let loadedIDs = Set(loaded.map(\.id))
        loaded += page.summaries.filter { !loadedIDs.contains($0.id) }
        nextPageIndex += 1
        hasNextPage = page.hasNextPage
        emit()
        return true
    }

    private func clearFirstPageTask(epoch: Int) {
        guard epoch == self.epoch else { return }
        firstPageTask = nil
    }

    private func clearNextPageTask(epoch: Int) {
        guard epoch == self.epoch else { return }
        nextPageTask = nil
    }

    private func reset() {
        epoch += 1
        resetEpoch = epoch
        firstPageTask = nil
        nextPageTask = nil
        loaded = []
        nextPageIndex = 0
        hasNextPage = false
        isLoaded = false
        emit()
    }

    private func emit() {
        let list = currentList
        for continuation in subscribers.values {
            continuation.yield(list)
        }
    }

    private func removeSubscriber(_ subscriberID: UUID) {
        subscribers.removeValue(forKey: subscriberID)
    }

}
