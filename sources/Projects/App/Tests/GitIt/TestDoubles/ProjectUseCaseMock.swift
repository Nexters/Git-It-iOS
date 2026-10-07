import DomainIdentifier
import DomainProject
import Foundation

actor ProjectUseCaseMock: ProjectUseCase {

    // MARK: Lifecycle

    init(refreshError: ProjectError? = nil) {
        self.refreshError = refreshError
    }

    // MARK: Internal

    private(set) var refreshCallCount = 0
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

    func requestNextPage() async throws { }

    func detail(of projectID: ProjectID) async throws -> ProjectDetail {
        AppRootTestFixture.projectDetail(projectID: projectID)
    }

    func delete(_ projectID: ProjectID) async throws {
        deletedProjectIDs.append(projectID)
    }

    // MARK: Private

    private let refreshError: ProjectError?

}
