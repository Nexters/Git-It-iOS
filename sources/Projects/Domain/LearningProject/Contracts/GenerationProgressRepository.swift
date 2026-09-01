public protocol GenerationProgressRepository: Sendable {
    func load() async -> GenerationProgress?
    func save(_ progress: GenerationProgress) async
    func clear() async
}
