import DataShared
import Foundation
import InfrastructureNetworkClient

// MARK: - BookmarkRemote

public struct BookmarkRemote: Sendable {

    // MARK: Lifecycle

    public init(
        baseURL: URL,
        transport: (any RequestTransport)?,
        responseTimeout: Duration,
        accessTokenProvider: @escaping @Sendable () async -> String?,
    ) {
        self.init(
            client: RequestClientFactory.makeClient(
                baseURL: baseURL,
                transport: transport,
                responseTimeout: responseTimeout,
            ),
            accessTokenProvider: accessTokenProvider,
        )
    }

    init(
        client: HTTPClient,
        accessTokenProvider: @escaping @Sendable () async -> String?,
    ) {
        executor = LearningProjectRequestExecutor(client: client, accessTokenProvider: accessTokenProvider)
    }

    // MARK: Public

    public func setBookmark(
        projectID: String,
        questionID: String,
        request: BookmarkQuestionRequestDTO,
    ) async throws -> BookmarkQuestionResponseDTO {
        try await executor.send(
            BookmarkEndpoint.set(projectID: projectID, questionID: questionID).request,
            body: request,
            expecting: BookmarkQuestionResponseDTO.self,
        )
    }

    public func fetchBookmarks(projectID: String?) async throws -> BookmarkedQuestionListResponseDTO {
        try await executor.send(
            BookmarkEndpoint.list(projectID: projectID).request,
            expecting: BookmarkedQuestionListResponseDTO.self,
        )
    }

    // MARK: Private

    private let executor: LearningProjectRequestExecutor

}
