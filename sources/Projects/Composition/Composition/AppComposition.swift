import DomainLearningProject

// MARK: - AppComposition

public struct AppComposition: Sendable {

    // MARK: Lifecycle

    public init(
        fetchLearningProjects: any FetchLearningProjects,
        deleteLearningProject: any DeleteLearningProject,
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

    public let fetchLearningProjects: any FetchLearningProjects
    public let deleteLearningProject: any DeleteLearningProject

    public static func live() -> Self {
        let store = SampleLearningProjectStore(initialPage: livePage())

        return Self(
            fetchLearningProjects: SampleFetchLearningProjects(store: store),
            deleteLearningProject: SampleDeleteLearningProject(store: store),
        )
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

    private static func livePage() -> LearningProjectPage {
        guard let projectID = LearningProjectID(rawValue: "git-it-ios") else {
            preconditionFailure("기본 학습 프로젝트 식별자는 비어 있지 않아야 합니다.")
        }

        return LearningProjectPage(
            projects: [
                LearningProjectSummary(
                    id: projectID,
                    name: "Git It iOS",
                    technologies: "Swift · SwiftUI · TCA",
                    progress: .init(completedRatio: 0.65),
                    nextSet: .init(order: 2, title: "Presentation 구조"),
                )
            ],
            hasNextPage: false,
        )
    }

    private static func emptyPage() -> LearningProjectPage {
        LearningProjectPage(
            projects: [],
            hasNextPage: false,
        )
    }

}

// MARK: - FailingFetchLearningProjects

private struct FailingFetchLearningProjects: FetchLearningProjects {
    func callAsFunction(
        page _: Int,
        size _: Int,
    ) async throws -> LearningProjectPage {
        throw LearningProjectError.temporarilyUnavailable
    }
}

// MARK: - PendingFetchLearningProjects

private struct PendingFetchLearningProjects: FetchLearningProjects {
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
