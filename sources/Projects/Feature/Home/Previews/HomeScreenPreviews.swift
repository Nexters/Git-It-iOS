import ComposableArchitecture
import DomainProject
import DomainUserInfo
import SwiftUI

private enum HomePreviewFixture {
    static let profile = UserProfile(
        detail: UserDetail(
            name: "프로덕션에 푸시하는 고양이",
            email: "cat@git-it.dev",
            statistics: .init(thisWeekSolvedCount: 12, thisMonthSolvedCount: 9, streakDays: 3, weeklyCounts: []),
        ),
        curation: Curation(position: .ios, careerLevel: .junior),
    )

    static func project(_ index: Int) -> ProjectSummary {
        ProjectSummary(
            id: "preview-\(index)",
            repositoryName: ["Nexters", "Now in Android", "Git It iOS"][index % 3],
            repositoryImageURL: nil,
            techStack: ["Swift", "SwiftUI", "TCA"],
            currentSet: ProjectSetLabel(label: "Set \(index + 1)", title: "Presentation 구조"),
            next: ProjectNextQuiz(setID: "set-\(index)", quizID: "quiz-\(index)"),
            progressPercent: 25 * (index + 1),
        )
    }

    static func list(_ summaries: [ProjectSummary]) -> ProjectList {
        ProjectList(summaries: summaries, hasNextPage: false, isLoaded: true)
    }

    @MainActor
    static func store(
        projectLoad: ProjectSummaryListFeature.State.Load,
        profileLoad: UserProfileLoadFeature.State.Load = .loaded(profile),
    ) -> StoreOf<HomeFeature> {
        Store(
            initialState: {
                var state = HomeFeature.State()
                state.projectSummaries.load = projectLoad
                state.profile.load = profileLoad
                return state
            }()
        ) { EmptyReducer() }
    }
}

#Preview("Project Present - 1465:19015") {
    HomeScreen(
        store: HomePreviewFixture.store(
            projectLoad: .loaded(
                HomePreviewFixture.list([
                    HomePreviewFixture.project(0),
                    HomePreviewFixture.project(1),
                    HomePreviewFixture.project(2),
                ])
            )
        )
    )
}

#Preview("Project Absent - 1542:19610") {
    HomeScreen(store: HomePreviewFixture.store(projectLoad: .loaded(HomePreviewFixture.list([]))))
}

#Preview("Loading") {
    HomeScreen(store: HomePreviewFixture.store(projectLoad: .loading))
}

#Preview("Project Failure as Empty - 1542:19610") {
    HomeScreen(store: HomePreviewFixture.store(projectLoad: .failed(.temporarilyUnavailable)))
}

#Preview("Home - guest") {
    HomeScreen(
        store: Store(
            initialState: {
                var state = HomeFeature.State()
                state.access = .guest
                return state
            }()
        ) { EmptyReducer() }
    )
}

#Preview("Profile Failure") {
    HomeScreen(
        store: HomePreviewFixture.store(
            projectLoad: .loaded(HomePreviewFixture.list([HomePreviewFixture.project(0)])),
            profileLoad: .failed(.temporarilyUnavailable),
        )
    )
}
