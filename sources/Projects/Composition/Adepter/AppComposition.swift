import DomainLearningProject
import Foundation
import InfrastructureNetworkClient

// MARK: - AppComposition

public struct AppComposition: Sendable {

    // MARK: Lifecycle

    public init(
        fetchLearningProjects: any FetchLearningProjectsUseCase,
        deleteLearningProject: any DeleteLearningProjectUseCase,
    ) {
        self.fetchLearningProjects = fetchLearningProjects
        self.deleteLearningProject = deleteLearningProject
    }

    // MARK: Public

    public enum SampleFetchBehavior: Sendable {
        case projects(LearningProjectPage)
        case failure
        case pending
    }

    public let fetchLearningProjects: any FetchLearningProjectsUseCase
    public let deleteLearningProject: any DeleteLearningProjectUseCase

    public static func live(
        serverBaseURL: URL,
        accessToken: @escaping @Sendable () async -> String?,
    ) -> Self {
        let bodyCoding = JSONBodyCodingAdapter()
        let serverClient = HTTPClient(baseURL: serverBaseURL, bodyCoding: bodyCoding)
        let remote = LearningProjectRemoteAdapter(
            httpClient: serverClient,
            accessToken: accessToken,
        )
        let repository = LearningProjectRepositoryAdapter(remote: remote)

        return Self(
            fetchLearningProjects: FetchLearningProjects(repository: repository),
            deleteLearningProject: DeleteLearningProject(repository: repository),
        )
    }

    public static func sample() -> Self {
        sample(fetch: .projects(samplePage()))
    }

    public static func sample(fetch behavior: SampleFetchBehavior) -> Self {
        switch behavior {
        case .projects(let page):
            let store = SampleLearningProjectStore(initialPage: page)
            return Self(
                fetchLearningProjects: SampleFetchLearningProjects(store: store),
                deleteLearningProject: SampleDeleteLearningProject(store: store),
            )

        case .failure:
            let store = SampleLearningProjectStore(initialPage: emptyPage())
            return Self(
                fetchLearningProjects: FailingFetchLearningProjects(),
                deleteLearningProject: SampleDeleteLearningProject(store: store),
            )

        case .pending:
            let store = SampleLearningProjectStore(initialPage: emptyPage())
            return Self(
                fetchLearningProjects: PendingFetchLearningProjects(),
                deleteLearningProject: SampleDeleteLearningProject(store: store),
            )
        }
    }

    // MARK: Private

    private static func samplePage() -> LearningProjectPage {
        LearningProjectPage(
            items: [
                LearningProjectSummary(
                    projectId: "git-it-ios",
                    repositoryName: "Git It iOS",
                    repositoryImageURL: nil,
                    techStack: ["Swift", "SwiftUI", "TCA"],
                    currentSetLabel: "Set 2",
                    currentSetTitle: "Presentation 구조",
                    nextSetId: "set-2",
                    nextQuestionId: "question-1",
                    overallProgressPercent: 65,
                )
            ],
            hasNext: false,
        )
    }

    private static func emptyPage() -> LearningProjectPage {
        LearningProjectPage(
            items: [],
            hasNext: false,
        )
    }

}

// MARK: - FailingFetchLearningProjects

private struct FailingFetchLearningProjects: FetchLearningProjectsUseCase {
    func callAsFunction(
        page _: Int,
        size _: Int,
    ) async throws -> LearningProjectPage {
        throw LearningProjectError.unexpected
    }
}

// MARK: - PendingFetchLearningProjects

private struct PendingFetchLearningProjects: FetchLearningProjectsUseCase {
    func callAsFunction(
        page _: Int,
        size _: Int,
    ) async throws -> LearningProjectPage {
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        defer { continuation.finish() }

        for await _ in stream { }
        try Task.checkCancellation()
        preconditionFailure("대기 표본은 취소 전에 완료되지 않아야 합니다.")
    }
}
