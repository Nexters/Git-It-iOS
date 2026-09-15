public protocol GenerationStateRepository: Sendable {
    func load() async -> GenerationState

    func save(_ state: GenerationState) async
}
