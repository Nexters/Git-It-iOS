@testable import DomainProject

actor StubProjectRepository: ProjectRepository {

    // MARK: Lifecycle

    init(
        pages: [Int: ProjectPage],
        holdsFirstRequest: Bool = false,
    ) {
        self.pages = pages
        holdsRequest = holdsFirstRequest
    }

    // MARK: Internal

    private(set) var requestedPageIndexes = [Int]()
    private(set) var deletedProjectIDs = [String]()

    func page(
        _ index: Int,
        size _: Int,
    ) async throws -> ProjectPage {
        requestedPageIndexes.append(index)
        if holdsRequest {
            await withCheckedContinuation { waiter = $0 }
        }
        if let failure {
            throw failure
        }
        return pages[index] ?? ProjectPage(
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

    func setFailure(_ failure: ProjectError?) {
        self.failure = failure
    }

    func release() {
        holdsRequest = false
        waiter?.resume()
        waiter = nil
    }

    // MARK: Private

    private var pages: [Int: ProjectPage]
    private var holdsRequest: Bool
    private var failure: ProjectError?
    private var waiter: CheckedContinuation<Void, Never>?

}
