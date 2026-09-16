import Testing

@testable import DomainLearningProject

// MARK: - RequestGenerationReminderTests

@Suite("RequestGenerationReminder")
struct RequestGenerationReminderTests {
    @Test
    func `권한이 허용되면 리마인드 대상으로 등록하고 결과를 그대로 반환한다`() async {
        let gateway = StubNotificationAuthorization(scriptedOutcome: .authorized)
        let registry = StubGenerationReminderRegistration()
        let requestGenerationReminder = RequestGenerationReminder(
            notificationAuthorization: gateway,
            reminderRegistration: registry,
        )

        let outcome = await requestGenerationReminder(projectID: "project-1")

        #expect(outcome == .authorized)
        #expect(await registry.registeredProjectIDs == ["project-1"])
    }

    @Test
    func `권한을 방금 거부하면 리마인드 대상으로 등록하지 않는다`() async {
        let gateway = StubNotificationAuthorization(scriptedOutcome: .declined)
        let registry = StubGenerationReminderRegistration()
        let requestGenerationReminder = RequestGenerationReminder(
            notificationAuthorization: gateway,
            reminderRegistration: registry,
        )

        let outcome = await requestGenerationReminder(projectID: "project-1")

        #expect(outcome == .declined)
        #expect(await registry.registeredProjectIDs.isEmpty)
    }

    @Test
    func `권한이 이미 거부된 상태면 리마인드 대상으로 등록하지 않는다`() async {
        let gateway = StubNotificationAuthorization(scriptedOutcome: .previouslyDenied)
        let registry = StubGenerationReminderRegistration()
        let requestGenerationReminder = RequestGenerationReminder(
            notificationAuthorization: gateway,
            reminderRegistration: registry,
        )

        let outcome = await requestGenerationReminder(projectID: "project-1")

        #expect(outcome == .previouslyDenied)
        #expect(await registry.registeredProjectIDs.isEmpty)
    }

    @Test
    func `isAuthorized는 gateway의 현재 권한 상태를 그대로 반환한다`() async {
        let gateway = StubNotificationAuthorization(scriptedOutcome: .authorized, isAuthorizedResult: true)
        let registry = StubGenerationReminderRegistration()
        let requestGenerationReminder = RequestGenerationReminder(
            notificationAuthorization: gateway,
            reminderRegistration: registry,
        )

        let isAuthorized = await requestGenerationReminder.isAuthorized()

        #expect(isAuthorized)
    }
}

// MARK: - StubNotificationAuthorization

private struct StubNotificationAuthorization: NotificationAuthorization {

    let scriptedOutcome: NotificationAuthorizationOutcome
    var isAuthorizedResult = false

    func requestAuthorization() async -> NotificationAuthorizationOutcome {
        scriptedOutcome
    }

    func isAuthorized() async -> Bool {
        isAuthorizedResult
    }

}

// MARK: - StubGenerationReminderRegistration

private actor StubGenerationReminderRegistration: GenerationReminderRegistration {

    private(set) var registeredProjectIDs = [String]()

    func register(projectID: String) async {
        registeredProjectIDs.append(projectID)
    }

}
