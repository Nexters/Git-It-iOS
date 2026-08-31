import DomainLearningProject

actor StubRequestGenerationReminderUseCase: RequestGenerationReminderUseCase {

    // MARK: Lifecycle

    init(results: [NotificationAuthorizationOutcome] = [.authorized], isAuthorizedResult: Bool = false) {
        self.results = results
        self.isAuthorizedResult = isAuthorizedResult
    }

    // MARK: Internal

    func callAsFunction(projectID: String) async -> NotificationAuthorizationOutcome {
        callCount += 1
        lastProjectID = projectID
        return nextResult()
    }

    func isAuthorized() async -> Bool {
        isAuthorizedResult
    }

    func snapshot() -> (callCount: Int, lastProjectID: String?) {
        (callCount, lastProjectID)
    }

    // MARK: Private

    private var results: [NotificationAuthorizationOutcome]
    private let isAuthorizedResult: Bool
    private var callCount = 0
    private var lastProjectID: String?

    private func nextResult() -> NotificationAuthorizationOutcome {
        guard !results.isEmpty else { return .declined }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
