public protocol QuizGenerationRemote: Sendable {
    func fetchGenerationStatus(projectID: String) async throws -> QuizGenerationStatusResponseDTO
    func retryQuizGeneration(projectID: String) async throws
}
