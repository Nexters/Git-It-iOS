import ComposableArchitecture
import DomainUserInfo
import SwiftUI

private enum SettingsPreviewFixture {
    static func profile(
        position: MemberPosition?,
        careerLevel: CareerLevel?,
    ) -> UserProfile {
        UserProfile(
            detail: UserDetail(
                name: "프로덕션에 푸시하는 고양이",
                email: "kimlee@github.io",
                statistics: LearningStatistics(
                    thisWeekSolvedCount: 0,
                    thisMonthSolvedCount: 0,
                    streakDays: 0,
                    weeklyCounts: [],
                ),
            ),
            curation: Self.curation(position: position, careerLevel: careerLevel),
        )
    }

    static func curation(
        position: MemberPosition?,
        careerLevel: CareerLevel?,
    ) -> Curation? {
        guard let position, let careerLevel else { return nil }
        return Curation(position: position, careerLevel: careerLevel)
    }

    @MainActor
    static func store(
        profile: UserProfile? = SettingsPreviewFixture.profile(position: .backend, careerLevel: .entry),
        accountAction: AccountActionFeature.State.AccountAction = .idle,
        positionMutation: CurationUpdateFeature.State.MutationStatus = .idle,
    ) -> StoreOf<SettingsFeature> {
        Store(
            initialState: {
                var state = SettingsFeature.State()
                state.userProfile.load = profile.map { .loaded($0) } ?? .failed(.temporarilyUnavailable)
                state.accountAction.accountAction = accountAction
                state.curationUpdate.positionMutation = positionMutation
                return state
            }()
        ) { EmptyReducer() }
    }
}

#Preview("Settings - 직군·연차 설정 - 1465:19689") {
    SettingsScreen(store: SettingsPreviewFixture.store())
}

#Preview("Settings - 직군·연차 미설정(선택 안 함) - 1465:19689") {
    SettingsScreen(
        store: SettingsPreviewFixture.store(profile: SettingsPreviewFixture.profile(position: nil, careerLevel: nil))
    )
}

#Preview("Settings - 프로필 조회 실패 - 1465:19689") {
    SettingsScreen(store: SettingsPreviewFixture.store(profile: nil))
}

#Preview("Settings - 개발 분야 선택 - 1535:18281") {
    SettingsScreen.PositionSelectionView(store: SettingsPreviewFixture.store())
}

#Preview("Settings - 개발 분야 변경 실패 - 1535:18281") {
    SettingsScreen.PositionSelectionView(
        store: SettingsPreviewFixture.store(positionMutation: .failed(.temporarilyUnavailable))
    )
}

#Preview("Settings - 개발 수준 선택 - 1535:18378") {
    SettingsScreen.CareerLevelSelectionView(store: SettingsPreviewFixture.store())
}

#Preview("Settings - 계정 삭제 확인 - 1636:31714") {
    SettingsScreen.AccountDeletionView(store: SettingsPreviewFixture.store(accountAction: .confirmingDeletion))
}

#Preview("Settings - 계정 삭제 실패 - 1636:31714") {
    SettingsScreen.AccountDeletionView(
        store: SettingsPreviewFixture.store(accountAction: .failed(.temporarilyUnavailable))
    )
}
