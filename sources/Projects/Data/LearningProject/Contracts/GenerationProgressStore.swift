public protocol GenerationProgressStore: Sendable {
    func load() async -> GenerationProgressDTO?

    func save(_ progress: GenerationProgressDTO) async

    func clear() async
}
