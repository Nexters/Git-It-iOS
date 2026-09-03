import ComposableArchitecture
import DomainLearningProject
import DomainMember
import SwiftUI

private enum HomePreviewFixture {
    static let profile = MemberProfile(
        name: "프로덕션에 푸시하는 고양이",
        email: "cat@git-it.dev",
        position: .ios,
        careerLevel: .junior,
        statistics: .init(totalAnsweredCount: 12, totalCorrectCount: 9, weeklyCounts: []),
    )

    static func project(_ index: Int) -> LearningProjectSummary {
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

    @MainActor
    static func store(
        projectLoad: HomeFeature.State.ProjectLoad,
        profileLoad: HomeFeature.State.ProfileLoad = .loaded(profile),
    ) -> StoreOf<HomeFeature> {
        Store(
            initialState: {
                var state = HomeFeature.State()
                state.projectLoad = projectLoad
                state.profileLoad = profileLoad
                return state
            }()
        ) { EmptyReducer() }
    }
}

#Preview("Project Present - 1465:19015") {
    HomeScreen(
        store: HomePreviewFixture.store(
            projectLoad: .loaded(
                .init(
                    items: [
                        HomePreviewFixture.project(0),
                        HomePreviewFixture.project(1),
                        HomePreviewFixture.project(2),
                    ],
                    hasNext: false,
                )
            )
        )
    )
}

#Preview("Project Absent - 1542:19610") {
    HomeScreen(store: HomePreviewFixture.store(projectLoad: .loaded(.init(items: [], hasNext: false))))
}

#Preview("Loading") {
    HomeScreen(store: HomePreviewFixture.store(projectLoad: .loading))
}

#Preview("Project Failure as Empty - 1542:19610") {
    HomeScreen(store: HomePreviewFixture.store(projectLoad: .failed(.temporarilyUnavailable)))
}

#Preview("Profile Failure") {
    HomeScreen(
        store: HomePreviewFixture.store(
            projectLoad: .loaded(.init(items: [HomePreviewFixture.project(0)], hasNext: false)),
            profileLoad: .failed(.temporarilyUnavailable),
        )
    )
}
