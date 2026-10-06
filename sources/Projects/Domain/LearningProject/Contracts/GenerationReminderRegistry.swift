public protocol GenerationReminderRegistry: Sendable {
    func register(projectID: String) async
}
