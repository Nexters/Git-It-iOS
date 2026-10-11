import DomainUseCaseInterface
import Foundation

actor ProjectUseCaseMock: ProjectUseCase {

    // MARK: Lifecycle

    init(
        refreshError: ProjectError? = nil,
        replacingRefreshError: ProjectError? = nil,
        holdsFirstReplacingRefresh: Bool = false,
    ) {
        self.refreshError = refreshError
        self.replacingRefreshError = replacingRefreshError
        holdsReplacingRefresh = holdsFirstReplacingRefresh
    }

    // MARK: Internal

    private(set) var refreshCallCount = 0
    private(set) var replacingRefreshCallCount = 0
    private(set) var isHeldReplacingRefreshCancelled = false
    private(set) var deletedProjectIDs = [ProjectID]()

    func projects() async -> AsyncStream<ProjectList> {
        AsyncStream { $0.finish() }
    }

    func refresh() async throws {
        refreshCallCount += 1
        if let refreshError {
            throw refreshError
        }
    }

    func refreshReplacingInFlightRequest() async throws {
        replacingRefreshCallCount += 1
        if holdsReplacingRefresh {
            holdsReplacingRefresh = false
            try await holdReplacingRefresh()
        }
        if let replacingRefreshError {
            throw replacingRefreshError
        }
    }

    func releaseHeldReplacingRefresh() {
        heldReplacingRefresh?.resume()
        heldReplacingRefresh = nil
    }

    func requestNextPage() async throws { }

    func detail(of projectID: ProjectID) async throws -> ProjectDetail {
        AppRootTestFixture.projectDetail(projectID: projectID)
    }

    func delete(_ projectID: ProjectID) async throws {
        deletedProjectIDs.append(projectID)
    }

    // MARK: Private

    private let refreshError: ProjectError?
    private let replacingRefreshError: ProjectError?
    private var holdsReplacingRefresh: Bool
    private var heldReplacingRefresh: CheckedContinuation<Void, any Error>?

    private func holdReplacingRefresh() async throws {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                heldReplacingRefresh = continuation
                if Task.isCancelled {
                    cancelHeldReplacingRefresh()
                }
            }
        } onCancel: {
            Task { await self.cancelHeldReplacingRefresh() }
        }
    }

    private func cancelHeldReplacingRefresh() {
        guard let heldReplacingRefresh else { return }
        isHeldReplacingRefreshCancelled = true
        heldReplacingRefresh.resume(throwing: CancellationError())
        self.heldReplacingRefresh = nil
    }

}
