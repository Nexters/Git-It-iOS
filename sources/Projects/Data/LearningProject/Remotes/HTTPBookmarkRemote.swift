import Foundation
import InfrastructureNetworkClient

// MARK: - HTTPBookmarkRemote

public struct HTTPBookmarkRemote: BookmarkRemote {

    // MARK: Lifecycle

    public init(
        client: HTTPClient,
        accessTokenProvider: @escaping @Sendable () async -> String?,
    ) {
        executor = LearningProjectHTTPExecutor(client: client, accessTokenProvider: accessTokenProvider)
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

    private let executor: LearningProjectHTTPExecutor

}
