public protocol ProjectGenerationRepository: Sendable {
    func register(_ request: ProjectGenerationRequest) async throws -> ProjectGenerationReceipt
}
