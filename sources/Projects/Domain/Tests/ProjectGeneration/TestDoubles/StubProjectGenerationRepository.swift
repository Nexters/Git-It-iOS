@testable import DomainProjectGeneration

actor StubProjectGenerationRepository: ProjectGenerationRepository {

    // MARK: Lifecycle

    init(error: ProjectGenerationError? = nil) {
        self.error = error
    }

    // MARK: Internal

    private(set) var requests = [ProjectGenerationRequest]()

    func register(_ request: ProjectGenerationRequest) async throws -> ProjectGenerationReceipt {
        requests.append(request)
        if let error {
            throw error
        }
        return ProjectGenerationReceipt(projectID: "p\(requests.count)", quizLevel: request.quizLevel)
    }

    // MARK: Private

    private let error: ProjectGenerationError?

}
