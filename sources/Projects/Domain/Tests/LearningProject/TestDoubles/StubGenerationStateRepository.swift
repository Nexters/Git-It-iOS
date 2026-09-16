@testable import DomainLearningProject

actor StubGenerationStateRepository: GenerationStateRepository {

    // MARK: Lifecycle

    init(stored: GenerationState = GenerationState()) {
        self.stored = stored
    }

    // MARK: Internal

    private(set) var saveCount = 0

    func currentState() async -> GenerationState {
        stored
    }

    func record(_ state: GenerationState) async {
        saveCount += 1
        stored = state
    }

    // MARK: Private

    private var stored: GenerationState

}
