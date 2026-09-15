public protocol GenerationStateStore: Sendable {
    func load() async -> GenerationStateDTO

    func save(_ state: GenerationStateDTO) async
}
