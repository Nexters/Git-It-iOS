public protocol ProjectRemote: Sendable {
    func registerProject(_ request: RegisterProjectRequestDTO) async throws -> RegisterProjectResponseDTO
    func fetchProjects(
        page: Int,
        size: Int,
    ) async throws -> ProjectListResponseDTO
    func fetchProjectDetail(projectID: String) async throws -> ProjectDetailResponseDTO
    func deleteProject(projectID: String) async throws
}
