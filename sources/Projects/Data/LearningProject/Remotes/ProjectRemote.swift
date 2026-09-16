import Foundation
import InfrastructureNetworkClient

// MARK: - ProjectRemote

public struct ProjectRemote: Sendable {

    // MARK: Lifecycle

    public init(
        client: HTTPClient,
        accessTokenProvider: @escaping @Sendable () async -> String?,
    ) {
        executor = LearningProjectRequestExecutor(client: client, accessTokenProvider: accessTokenProvider)
    }

    // MARK: Public

    public func registerProject(_ request: RegisterProjectRequestDTO) async throws -> RegisterProjectResponseDTO {
        try await executor.send(
            LearningProjectRequest(method: .post, path: LearningProjectRequest.basePath),
            body: request,
            expecting: RegisterProjectResponseDTO.self,
        )
    }

    public func fetchProjects(
        page: Int,
        size: Int,
    ) async throws -> ProjectListResponseDTO {
        try await executor.send(
            LearningProjectRequest(
                method: .get,
                path: LearningProjectRequest.basePath,
                queryItems: ["page": String(page), "size": String(size)],
            ),
            expecting: ProjectListResponseDTO.self,
        )
    }

    public func fetchProjectDetail(projectID: String) async throws -> ProjectDetailResponseDTO {
        try await executor.send(
            LearningProjectRequest(method: .get, path: "\(LearningProjectRequest.basePath)/\(projectID)"),
            expecting: ProjectDetailResponseDTO.self,
        )
    }

    public func deleteProject(projectID: String) async throws {
        _ = try await executor.send(
            LearningProjectRequest(method: .delete, path: "\(LearningProjectRequest.basePath)/\(projectID)"),
            expecting: EmptyResponseData.self,
        )
    }

    // MARK: Private

    private let executor: LearningProjectRequestExecutor

}
