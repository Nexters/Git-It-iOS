public protocol GenerationReminderRegistration: Sendable {
    func register(projectID: String) async
}
