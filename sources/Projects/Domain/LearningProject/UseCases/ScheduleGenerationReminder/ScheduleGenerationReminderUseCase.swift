public protocol ScheduleGenerationReminderUseCase: GenerationReminderRegistration {
    func absorbPendingReminders() async
    func start(trackGeneration: any TrackGenerationUseCase) async
    func waitUntilObservationFinished() async
}
