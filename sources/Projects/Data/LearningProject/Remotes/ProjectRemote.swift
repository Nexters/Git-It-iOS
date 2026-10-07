import DataShared
import Foundation
import InfrastructureNetworkClient

// MARK: - ProjectRemote

public struct ProjectRemote: Sendable {

    // MARK: Lifecycle

    public init(
        baseURL: URL,
        transport: (any RequestTransport)?,
        responseTimeout: Duration,
        credential: @escaping @Sendable () async -> RequestCredential,
        credentialRejected: @escaping @Sendable () async -> Void,
    ) {
        self.init(
            client: RequestClientFactory.makeClient(
                baseURL: baseURL,
                transport: transport,
                responseTimeout: responseTimeout,
            ),
            credential: credential,
            credentialRejected: credentialRejected,
        )
    }

    init(
        client: HTTPClient,
        credential: @escaping @Sendable () async -> RequestCredential,
        credentialRejected: @escaping @Sendable () async -> Void,
    ) {
        executor = LearningProjectRequestExecutor(
            client: client,
            credential: credential,
            credentialRejected: credentialRejected,
        )
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
