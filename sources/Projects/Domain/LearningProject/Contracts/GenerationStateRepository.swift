public protocol GenerationStateRepository: Sendable {
    func currentState() async -> GenerationState

    func record(_ state: GenerationState) async
}
