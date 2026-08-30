import ComposableArchitecture
import DomainLearningProject
import DomainMember

@MainActor
enum HomePreviewSupport {
    static let projectPresent = store(
        projects: .success(.init(items: [project(0), project(1), project(2)], hasNext: false)),
        profile: .success(profile),
    )

    static let projectAbsent = store(
        projects: .success(.init(items: [], hasNext: false)),
        profile: .success(profile),
    )

    static let loading = store(projects: .loading, profile: .success(profile))
    static let projectFailure = store(projects: .failure(.temporarilyUnavailable), profile: .success(profile))
    static let profileFailure = store(
        projects: .success(.init(items: [project(0)], hasNext: false)),
        profile: .failure(.temporarilyUnavailable),
    )

    private static let profile = MemberProfile(
        name: "프로덕션에 푸시하는 고양이",
        email: "cat@git-it.dev",
        position: .ios,
        careerLevel: .junior,
        statistics: .init(totalAnsweredCount: 12, totalCorrectCount: 9, weeklyCounts: []),
    )

    private static func project(_ index: Int) -> LearningProjectSummary {
        LearningProjectSummary(
            projectID: "preview-\(index)",
            repositoryName: ["Nexters", "Now in Android", "Git It iOS"][index % 3],
            repositoryImageURL: nil,
            techStack: ["Swift", "SwiftUI", "TCA"],
            currentSetLabel: "Set \(index + 1)",
            currentSetTitle: "Presentation 구조",
            nextSetID: "set-\(index)",
            nextQuestionID: "question-\(index)",
            overallProgressPercent: 25 * (index + 1),
        )
    }

    private static func store(
        projects: HomePreviewFetchLearningProjects.Behavior,
        profile: HomePreviewFetchMemberProfile.Behavior,
    ) -> StoreOf<HomeFeature> {
        Store(initialState: HomeFeature.State()) {
            HomeFeature(
                fetchLearningProjects: HomePreviewFetchLearningProjects(behavior: projects),
                fetchMemberProfile: HomePreviewFetchMemberProfile(behavior: profile),
                observeLearningProjectGenerationOutcomes: HomePreviewObserveLearningProjectGenerationOutcomes(),
            )
        }
    }
}

// MARK: - HomePreviewObserveLearningProjectGenerationOutcomes

private struct HomePreviewObserveLearningProjectGenerationOutcomes: ObserveLearningProjectGenerationOutcomesUseCase {
    func callAsFunction() async -> AsyncStream<LearningProjectGenerationOutcome> {
        AsyncStream { _ in }
    }
}
