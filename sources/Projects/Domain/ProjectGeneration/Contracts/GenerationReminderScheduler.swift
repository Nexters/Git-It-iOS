import DomainIdentifier
import Foundation

public protocol GenerationReminderScheduler: Sendable {
    func isAuthorized() async -> Bool
    func schedule(
        _ reminder: GenerationReminder,
        at date: Date,
    ) async
    func cancel(projectID: ProjectID) async
}
