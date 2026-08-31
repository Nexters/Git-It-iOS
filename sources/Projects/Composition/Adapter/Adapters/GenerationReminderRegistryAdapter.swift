import DomainLearningProject

// MARK: - GenerationReminderRegistryAdapter

struct GenerationReminderRegistryAdapter: GenerationReminderRegistry {

    let coordinator: GenerationCompletionReminderCoordinator

    func register(projectID: String) async {
        await coordinator.register(projectID: projectID)
    }

}
