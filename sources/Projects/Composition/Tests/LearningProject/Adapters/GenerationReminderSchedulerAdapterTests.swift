import Testing
@testable import CompositionLearningProject

// MARK: - GenerationReminderSchedulerAdapterTests

@Suite("GenerationReminderSchedulerAdapter")
struct GenerationReminderSchedulerAdapterTests {

    @Test
    func `프로젝트 알림 취소는 완료·실패 식별자를 모두 취소한다`() async {
        let reminderNotifier = SpyLocalReminderNotifier()
        let adapter = GenerationReminderSchedulerAdapter(
            reminderNotifier: reminderNotifier,
            completedTitle: "completed",
            completedBody: "completed body",
            failedTitle: "failed",
            failedBody: "failed body",
        )

        await adapter.cancel(projectID: "project-1")

        #expect(await reminderNotifier.cancelledIdentifiers == [
            "generation-completed-project-1",
            "generation-failed-project-1",
        ])
    }

}
