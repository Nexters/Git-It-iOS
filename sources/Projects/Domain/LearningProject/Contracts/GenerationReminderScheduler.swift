import Foundation

// MARK: - GenerationReminderScheduler

public protocol GenerationReminderScheduler: Sendable {
    func isAuthorized() async -> Bool
    func schedule(identifier: String, at date: Date) async
}
