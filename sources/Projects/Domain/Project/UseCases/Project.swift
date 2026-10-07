import DomainIdentifier
import Foundation

public actor Project: ProjectUseCase {

    // MARK: Lifecycle

    public init(
        repository: any ProjectRepository,
        preparingProjectIDs: @escaping @Sendable () async -> AsyncStream<Set<ProjectID>>,
        signedOutEvents: @escaping @Sendable () async -> AsyncStream<Void>,
        pageSize: Int = 20,
    ) {
        self.repository = repository
        self.preparingProjectIDs = preparingProjectIDs
        self.signedOutEvents = signedOutEvents
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

    public func requestNextPage() async throws {
        startObserving()
        if let nextPageTask {
            try await nextPageTask.value
            return
        }
        guard hasNextPage else { return }
        let repository = repository
        let index = nextPageIndex
        let size = pageSize
        let epoch = epoch
        let task = Task<Void, Error> {
            let page = try await repository.page(index, size: size)
            self.appendPage(page, epoch: epoch)
        }
        nextPageTask = task
        defer { clearNextPageTask(epoch: epoch) }
        try await task.value
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
    }

    // MARK: Private

    private let repository: any ProjectRepository
    private let preparingProjectIDs: @Sendable () async -> AsyncStream<Set<ProjectID>>
    private let signedOutEvents: @Sendable () async -> AsyncStream<Void>
    private let pageSize: Int

    private var loaded = [ProjectSummary]()
    private var nextPageIndex = 0
    private var hasNextPage = false
    private var isLoaded = false
    private var excludedIDs = Set<ProjectID>()
    private var epoch = 0
    private var firstPageTask: Task<Void, Error>?
    private var nextPageTask: Task<Void, Error>?
    private var subscribers = [UUID: AsyncStream<ProjectList>.Continuation]()
    private var observationTasks = [Task<Void, Never>]()

    private var currentList: ProjectList {
        ProjectList(
            summaries: loaded.filter { !excludedIDs.contains($0.id) },
            hasNextPage: hasNextPage,
            isLoaded: isLoaded,
        )
    }

    private func startObserving() {
        guard observationTasks.isEmpty else { return }
        let preparingProjectIDs = preparingProjectIDs
        let signedOutEvents = signedOutEvents
        observationTasks = [
            Task { [weak self] in
                for await projectIDs in await preparingProjectIDs() {
                    await self?.exclude(projectIDs)
                }
            },
            Task { [weak self] in
                for await _ in await signedOutEvents() {
                    await self?.reset()
                }
            },
        ]
    }

    private func requestFirstPage() async throws {
        if let firstPageTask {
            try await firstPageTask.value
            return
        }
        let repository = repository
        let size = pageSize
        let epoch = epoch
        let task = Task<Void, Error> {
            let page = try await repository.page(0, size: size)
            self.replaceWithFirstPage(page, epoch: epoch)
        }
        firstPageTask = task
        defer { clearFirstPageTask(epoch: epoch) }
        try await task.value
    }

    private func replaceWithFirstPage(
        _ page: ProjectPage,
        epoch: Int,
    ) {
        guard epoch == self.epoch else { return }
        loaded = page.summaries
        nextPageIndex = 1
        hasNextPage = page.hasNextPage
        isLoaded = true
        emit()
    }

    private func appendPage(
        _ page: ProjectPage,
        epoch: Int,
    ) {
        guard epoch == self.epoch else { return }
        let loadedIDs = Set(loaded.map(\.id))
        loaded += page.summaries.filter { !loadedIDs.contains($0.id) }
        nextPageIndex += 1
        hasNextPage = page.hasNextPage
        emit()
    }

    private func clearFirstPageTask(epoch: Int) {
        guard epoch == self.epoch else { return }
        firstPageTask = nil
    }

    private func clearNextPageTask(epoch: Int) {
        guard epoch == self.epoch else { return }
        nextPageTask = nil
    }

    private func exclude(_ projectIDs: Set<ProjectID>) async {
        let released = excludedIDs.subtracting(projectIDs)
        excludedIDs = projectIDs
        emit()
        guard !released.isEmpty, isLoaded else { return }
        try? await requestFirstPage()
    }

    private func reset() {
        epoch += 1
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
