@testable import DomainProject

actor StubProjectRepository: ProjectRepository {

    // MARK: Lifecycle

    init(
        pages: [Int: ProjectPage],
        holdsFirstRequest: Bool = false,
        heldRequestNumbers: Set<Int> = [],
        ignoresCancellation: Bool = false,
    ) {
        self.pages = pages
        holdsRequest = holdsFirstRequest
        self.heldRequestNumbers = heldRequestNumbers
        self.ignoresCancellation = ignoresCancellation
    }

    // MARK: Internal

    private(set) var requestedPageIndexes = [Int]()
    private(set) var deletedProjectIDs = [String]()
    private(set) var cancelledRequestNumbers = [Int]()

    func page(
        _ index: Int,
        size _: Int,
    ) async throws -> ProjectPage {
        let requestNumber = requestedPageIndexes.count
        requestedPageIndexes.append(index)
        if holdsRequest {
            await withCheckedContinuation { waiter = $0 }
        }
        if heldRequestNumbers.contains(requestNumber) {
            try await hold(requestNumber)
        }
        if let failure {
            throw failure
        }
        return responses[requestNumber] ?? pages[index] ?? ProjectPage(
            summaries: [],
            hasNextPage: false,
        )
    }

    func detail(of _: String) async throws -> ProjectDetail {
        throw ProjectError.notFound
    }

    func delete(_ projectID: String) async throws {
        deletedProjectIDs.append(projectID)
    }

    func setPage(
        _ page: ProjectPage,
        at index: Int,
    ) {
        pages[index] = page
    }

    func setPage(
        _ page: ProjectPage,
        forRequest requestNumber: Int,
    ) {
        responses[requestNumber] = page
    }

    func setFailure(_ failure: ProjectError?) {
        self.failure = failure
    }

    func release() {
        holdsRequest = false
        waiter?.resume()
        waiter = nil
    }

    func release(request requestNumber: Int) {
        heldRequestNumbers.remove(requestNumber)
        heldWaiters.removeValue(forKey: requestNumber)?.resume()
    }

    // MARK: Private

    private var pages: [Int: ProjectPage]
    private var responses = [Int: ProjectPage]()
    private var holdsRequest: Bool
    private var heldRequestNumbers: Set<Int>
    private let ignoresCancellation: Bool
    private var failure: ProjectError?
    private var waiter: CheckedContinuation<Void, Never>?
    private var heldWaiters = [Int: CheckedContinuation<Void, any Error>]()

    private func hold(_ requestNumber: Int) async throws {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                heldWaiters[requestNumber] = continuation
                if Task.isCancelled {
                    cancel(requestNumber)
                }
            }
        } onCancel: {
            Task { await self.cancel(requestNumber) }
        }
    }

    private func cancel(_ requestNumber: Int) {
        guard
            heldWaiters[requestNumber] != nil,
            !cancelledRequestNumbers.contains(requestNumber)
        else { return }
        cancelledRequestNumbers.append(requestNumber)
        guard !ignoresCancellation else { return }
        heldWaiters.removeValue(forKey: requestNumber)?.resume(throwing: CancellationError())
    }

}
