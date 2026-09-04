import ComposableArchitecture
import DomainMember
import Foundation
import Testing

@testable import Feature

@MainActor
@Suite("SettingsFeature 프로필 조회와 직군·연차 저장")
struct SettingsFeatureTests {

    // MARK: Internal

    @Test
    func `task는 프로필을 조회해 설정 값의 근거로 남긴다`() async {
        let fetchMemberProfile = FetchMemberProfileUseCaseMock(results: [.success(SettingsTestFixture.curatedProfile)])
        let store = makeStore(fetchMemberProfile: fetchMemberProfile)

        await store.send(.view(.task)) {
            $0.profileLoad = .loading
        }
        await store.receive(.effect(.profileLoadFinished(.success(SettingsTestFixture.curatedProfile)))) {
            $0.profile = SettingsTestFixture.curatedProfile
            $0.profileLoad = .loaded
        }

        #expect(await fetchMemberProfile.snapshot() == 1)
    }

    @Test
    func `프로필 조회 실패는 값 없이 실패 상태만 남긴다`() async {
        let store = makeStore(
            fetchMemberProfile: FetchMemberProfileUseCaseMock(results: [.failure(.temporarilyUnavailable)])
        )

        await store.send(.view(.task)) {
            $0.profileLoad = .loading
        }
        await store.receive(.effect(.profileLoadFinished(.failure(.temporarilyUnavailable)))) {
            $0.profileLoad = .failed(.temporarilyUnavailable)
        }

        #expect(store.state.profile == nil)
    }

    @Test
    func `직군 저장 성공은 직군만 바꾸고 연차와 통계를 유지한다`() async {
        let updateMemberPosition = UpdateMemberPositionUseCaseMock()
        let store = makeStore(
            state: makeState(profile: SettingsTestFixture.curatedProfile),
            updateMemberPosition: updateMemberPosition,
        )

        await store.send(.view(.positionSelected(.ios))) {
            $0.positionMutation = .committing
        }
        await store.receive(.effect(.positionUpdateFinished(.ios, nil))) {
            $0.positionMutation = .idle
            $0.profile = SettingsTestFixture.profile(position: .ios, careerLevel: .entry)
        }

        #expect(await updateMemberPosition.snapshot() == [.ios])
    }

    @Test
    func `연차 저장 성공은 연차만 바꾸고 직군과 통계를 유지한다`() async {
        let updateMemberCareerLevel = UpdateMemberCareerLevelUseCaseMock()
        let store = makeStore(
            state: makeState(profile: SettingsTestFixture.curatedProfile),
            updateMemberCareerLevel: updateMemberCareerLevel,
        )

        await store.send(.view(.careerLevelSelected(.senior))) {
            $0.careerLevelMutation = .committing
        }
        await store.receive(.effect(.careerLevelUpdateFinished(.senior, nil))) {
            $0.careerLevelMutation = .idle
            $0.profile = SettingsTestFixture.profile(position: .backend, careerLevel: .senior)
        }

        #expect(await updateMemberCareerLevel.snapshot() == [.senior])
    }

    @Test
    func `저장 실패는 실패 상태를 남기고 이전 프로필을 그대로 둔다`() async {
        let store = makeStore(
            state: makeState(profile: SettingsTestFixture.curatedProfile),
            updateMemberPosition: UpdateMemberPositionUseCaseMock(errors: [.temporarilyUnavailable]),
        )

        await store.send(.view(.positionSelected(.ios))) {
            $0.positionMutation = .committing
        }
        await store.receive(.effect(.positionUpdateFinished(.ios, .temporarilyUnavailable))) {
            $0.positionMutation = .failed(.temporarilyUnavailable)
        }

        #expect(store.state.profile == SettingsTestFixture.curatedProfile)
    }

    @Test
    func `저장 중에는 같은 항목의 선택을 다시 보내지 않는다`() async {
        let updateMemberPosition = UpdateMemberPositionUseCaseMock()
        var state = makeState(profile: SettingsTestFixture.curatedProfile)
        state.positionMutation = .committing
        let store = makeStore(state: state, updateMemberPosition: updateMemberPosition)

        await store.send(.view(.positionSelected(.ios)))

        #expect(await updateMemberPosition.snapshot().isEmpty)
    }

    @Test(arguments: zip(
        [SettingsFeature.Action.View.backTapped, .positionRowTapped, .careerLevelRowTapped],
        [
            SettingsFeature.Action.Delegate.backRequested,
            .positionSelectionRequested,
            .careerLevelSelectionRequested,
        ],
    ))
    func `이동 행 탭은 대응하는 delegate만 올린다`(
        view: SettingsFeature.Action.View,
        delegate: SettingsFeature.Action.Delegate,
    ) async {
        let store = makeStore()

        await store.send(.view(view))
        await store.receive(.delegate(delegate))
    }

    @Test
    func `서비스 약관 행은 서비스 정책 URL을 외부 링크 요청으로 올린다`() async throws {
        let url = try #require(URL(string: SettingsTestFixture.servicePolicyURLString))
        let store = makeStore()

        await store.send(.view(.termsTapped))
        await store.receive(.delegate(.externalURLRequested(url)))
    }

    // MARK: Private

    private func makeState(profile: MemberProfile) -> SettingsFeature.State {
        var state = SettingsFeature.State()
        state.profile = profile
        state.profileLoad = .loaded
        return state
    }

    private func makeStore(
        state: SettingsFeature.State = SettingsFeature.State(),
        fetchMemberProfile: FetchMemberProfileUseCaseMock = FetchMemberProfileUseCaseMock(),
        updateMemberPosition: UpdateMemberPositionUseCaseMock = UpdateMemberPositionUseCaseMock(),
        updateMemberCareerLevel: UpdateMemberCareerLevelUseCaseMock = UpdateMemberCareerLevelUseCaseMock(),
    ) -> TestStoreOf<SettingsFeature> {
        TestStore(initialState: state) {
            SettingsFeature(
                signOut: SignOutUseCaseMock(),
                fetchMemberProfile: fetchMemberProfile,
                updateMemberPosition: updateMemberPosition,
                updateMemberCareerLevel: updateMemberCareerLevel,
                deleteMemberAccount: DeleteMemberAccountUseCaseMock(),
            )
        }
    }

}
