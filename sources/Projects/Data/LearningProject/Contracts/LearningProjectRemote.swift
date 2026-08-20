public protocol LearningProjectRemote: Sendable {
    func registerProject(_ request: RegisterProjectRequestDTO) async throws -> RegisterProjectResponseDTO
    func fetchProjects(
        page: Int,
        size: Int,
    ) async throws -> ProjectListResponseDTO
    func fetchProjectDetail(projectId: String) async throws -> ProjectDetailResponseDTO
    func deleteProject(projectId: String) async throws
}
