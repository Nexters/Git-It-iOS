import DomainLearningProject

actor StubRequestGenerationReminderUseCase: RequestGenerationReminderUseCase {

    // MARK: Lifecycle

    init(results: [NotificationAuthorizationOutcome] = [.authorized]) {
        self.results = results
    }

    // MARK: Internal

    func callAsFunction(projectID: String) async -> NotificationAuthorizationOutcome {
        callCount += 1
        lastProjectID = projectID
        return nextResult()
    }

    func snapshot() -> (callCount: Int, lastProjectID: String?) {
        (callCount, lastProjectID)
    }

    // MARK: Private

    private var results: [NotificationAuthorizationOutcome]
    private var callCount = 0
    private var lastProjectID: String?

    private func nextResult() -> NotificationAuthorizationOutcome {
        guard !results.isEmpty else { return .declined }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
