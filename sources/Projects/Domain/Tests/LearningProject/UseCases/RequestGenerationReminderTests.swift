import Testing

@testable import DomainLearningProject

// MARK: - RequestGenerationReminderTests

@Suite("RequestGenerationReminder")
struct RequestGenerationReminderTests {
    @Test
    func `권한이 허용되면 리마인드 대상으로 등록하고 결과를 그대로 반환한다`() async {
        let gateway = StubNotificationAuthorizationGateway(scriptedOutcome: .authorized)
        let registry = StubGenerationReminderRegistry()
        let requestGenerationReminder = RequestGenerationReminder(
            authorizationGateway: gateway,
            reminderRegistry: registry
        )

        let outcome = await requestGenerationReminder(projectID: "project-1")

        #expect(outcome == .authorized)
        #expect(await registry.registeredProjectIDs == ["project-1"])
    }

    @Test
    func `권한을 방금 거부하면 리마인드 대상으로 등록하지 않는다`() async {
        let gateway = StubNotificationAuthorizationGateway(scriptedOutcome: .declined)
        let registry = StubGenerationReminderRegistry()
        let requestGenerationReminder = RequestGenerationReminder(
            authorizationGateway: gateway,
            reminderRegistry: registry
        )

        let outcome = await requestGenerationReminder(projectID: "project-1")

        #expect(outcome == .declined)
        #expect(await registry.registeredProjectIDs.isEmpty)
    }

    @Test
    func `권한이 이미 거부된 상태면 리마인드 대상으로 등록하지 않는다`() async {
        let gateway = StubNotificationAuthorizationGateway(scriptedOutcome: .previouslyDenied)
        let registry = StubGenerationReminderRegistry()
        let requestGenerationReminder = RequestGenerationReminder(
            authorizationGateway: gateway,
            reminderRegistry: registry
        )

        let outcome = await requestGenerationReminder(projectID: "project-1")

        #expect(outcome == .previouslyDenied)
        #expect(await registry.registeredProjectIDs.isEmpty)
    }
}

// MARK: - StubNotificationAuthorizationGateway

private struct StubNotificationAuthorizationGateway: NotificationAuthorizationGateway {

    let scriptedOutcome: NotificationAuthorizationOutcome

    func requestAuthorization() async -> NotificationAuthorizationOutcome {
        scriptedOutcome
    }

}

// MARK: - StubGenerationReminderRegistry

private actor StubGenerationReminderRegistry: GenerationReminderRegistry {

    private(set) var registeredProjectIDs: [String] = []

    func register(projectID: String) async {
        registeredProjectIDs.append(projectID)
    }

}
