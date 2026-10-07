public protocol ScheduleGenerationReminderUseCase: GenerationReminderRegistry {
    func absorbPendingReminders() async
    func start(trackGeneration: any TrackGenerationUseCase) async
    func waitUntilObservationFinished() async
}
