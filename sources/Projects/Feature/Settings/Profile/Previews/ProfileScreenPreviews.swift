import ComposableArchitecture
import DomainUserInfo
import SwiftUI

private enum ProfilePreviewFixture {
    static let weeklyCounts = [
        WeeklyLearningCount(
            dayLabel: "월",
            count: 3,
        ),
        WeeklyLearningCount(
            dayLabel: "화",
            count: 0,
        ),
        WeeklyLearningCount(
            dayLabel: "수",
            count: 5,
        ),
        WeeklyLearningCount(
            dayLabel: "목",
            count: 2,
        ),
        WeeklyLearningCount(
            dayLabel: "금",
            count: 0,
        ),
        WeeklyLearningCount(
            dayLabel: "토",
            count: 1,
        ),
        WeeklyLearningCount(
            dayLabel: "일",
            count: 0,
        ),
    ]

    static let emptyStatistics = LearningStatistics(
        thisWeekSolvedCount: 0,
        thisMonthSolvedCount: 0,
        streakDays: 0,
        weeklyCounts: [],
    )

    static let activeStatistics = LearningStatistics(
        thisWeekSolvedCount: 11,
        thisMonthSolvedCount: 27,
        streakDays: 4,
        weeklyCounts: weeklyCounts,
    )

    static func profile(
        position: MemberPosition?,
        careerLevel: CareerLevel?,
        statistics: LearningStatistics,
    ) -> UserProfile {
        UserProfile(
            detail: UserDetail(
                name: "프로덕션에 푸시하는 고양이",
                email: "kimlee@github.io",
                statistics: statistics,
            ),
            curation: Self.curation(
                position: position,
                careerLevel: careerLevel,
            ),
        )
    }

    static func curation(
        position: MemberPosition?,
        careerLevel: CareerLevel?,
    ) -> Curation? {
        guard let position, let careerLevel else { return nil }
        return Curation(
            position: position,
            careerLevel: careerLevel,
        )
    }

    @MainActor
    static func store(profileLoad: UserProfileLoadFeature.State.Load) -> StoreOf<ProfileFeature> {
        Store(
            initialState: {
                var state = ProfileFeature.State()
                state.profile.load = profileLoad
                return state
            }()
        ) { EmptyReducer() }
    }
}

#Preview("Profile - 직군·연차 설정, 풀이 없음 - 1539:19209") {
    ProfileScreen(
        store: ProfilePreviewFixture.store(
            profileLoad: .loaded(ProfilePreviewFixture.profile(
                position: .backend,
                careerLevel: .entry,
                statistics: ProfilePreviewFixture.emptyStatistics,
            ))
        )
    )
}

#Preview("Profile - 주간 풀이 있음 - 1539:19209") {
    ProfileScreen(
        store: ProfilePreviewFixture.store(
            profileLoad: .loaded(ProfilePreviewFixture.profile(
                position: .ios,
                careerLevel: .junior,
                statistics: ProfilePreviewFixture.activeStatistics,
            ))
        )
    )
}

#Preview("Profile - 직군·연차 미설정 - 1539:19209") {
    ProfileScreen(
        store: ProfilePreviewFixture.store(
            profileLoad: .loaded(ProfilePreviewFixture.profile(
                position: nil,
                careerLevel: nil,
                statistics: ProfilePreviewFixture.emptyStatistics,
            ))
        )
    )
}

#Preview("Profile - 로딩") {
    ProfileScreen(store: ProfilePreviewFixture.store(profileLoad: .loading))
}

#Preview("Profile - 조회 실패") {
    ProfileScreen(store: ProfilePreviewFixture.store(profileLoad: .failed(.temporarilyUnavailable)))
}
