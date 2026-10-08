import ComposableArchitecture
import Testing

@testable import Feature

@MainActor
@Suite("ProfileFeature 프로필 조회 합성")
struct ProfileFeatureTests {

    // MARK: Internal

    @Test
    func `최초 task는 프로필 조회에 load를 보내 받은 프로필을 노출한다`() async {
        let fetchMemberProfile = UserInfoUseCaseProfileMock(results: [.success(SettingsTestFixture.curatedProfile)])
        let store = makeStore(fetchMemberProfile: fetchMemberProfile)

        await store.send(.view(.task))
        await store.receive(.profile(.input(.load))) {
            $0.profile.load = .loading
            $0.profile.requestID = 1
        }
        await store.receive(.profile(.effect(.profileLoadFinished(
            requestID: 1,
            result: .success(SettingsTestFixture.curatedProfile),
        )))) {
            $0.profile.load = .loaded(SettingsTestFixture.curatedProfile)
        }

        #expect(await fetchMemberProfile.snapshot() == 1)
    }

    @Test
    func `이미 받은 프로필이 있으면 task는 로딩 없는 reload를 보낸다`() async {
        let updated = SettingsTestFixture.profile(
            position: .ios,
            careerLevel: .senior,
        )
        let store = makeStore(
            state: makeState(load: .loaded(SettingsTestFixture.curatedProfile)),
            fetchMemberProfile: UserInfoUseCaseProfileMock(results: [.success(updated)]),
        )

        await store.send(.view(.task))
        await store.receive(.profile(.input(.reload))) {
            $0.profile.requestID = 1
        }
        await store.receive(.profile(.effect(.profileLoadFinished(
            requestID: 1,
            result: .success(updated),
        )))) {
            $0.profile.load = .loaded(updated)
        }
    }

    @Test
    func `실패 상태의 재시도는 프로필 조회에 load를 보낸다`() async {
        let fetchMemberProfile = UserInfoUseCaseProfileMock(results: [.success(SettingsTestFixture.curatedProfile)])
        let store = makeStore(
            state: makeState(load: .failed(.temporarilyUnavailable)),
            fetchMemberProfile: fetchMemberProfile,
        )

        await store.send(.view(.retryTapped))
        await store.receive(.profile(.input(.load))) {
            $0.profile.load = .loading
            $0.profile.requestID = 1
        }
        await store.receive(.profile(.effect(.profileLoadFinished(
            requestID: 1,
            result: .success(SettingsTestFixture.curatedProfile),
        )))) {
            $0.profile.load = .loaded(SettingsTestFixture.curatedProfile)
        }

        #expect(await fetchMemberProfile.snapshot() == 1)
    }

    @Test
    func `실패 상태가 아니면 재시도는 조회하지 않는다`() async {
        let fetchMemberProfile = UserInfoUseCaseProfileMock(results: [.success(SettingsTestFixture.curatedProfile)])
        let store = makeStore(
            state: makeState(load: .loaded(SettingsTestFixture.curatedProfile)),
            fetchMemberProfile: fetchMemberProfile,
        )

        await store.send(.view(.retryTapped))

        #expect(await fetchMemberProfile.snapshot() == 0)
    }

    @Test
    func `조회 중인 동안 다시 들어온 task는 조회를 새로 시작하지 않는다`() async {
        let fetchMemberProfile = UserInfoUseCaseProfileMock(results: [.success(SettingsTestFixture.curatedProfile)])
        var initialState = makeState(load: .loading)
        initialState.profile.requestID = 1
        let store = makeStore(
            state: initialState,
            fetchMemberProfile: fetchMemberProfile,
        )

        await store.send(.view(.task))

        #expect(await fetchMemberProfile.snapshot() == 0)
    }

    @Test
    func `설정 아이콘 탭은 설정 요청 delegate를 올린다`() async {
        let store = makeStore()

        await store.send(.view(.settingsTapped))
        await store.receive(.delegate(.settingsRequested))
    }

    // MARK: Private

    private func makeState(load: UserProfileLoadFeature.State.Load) -> ProfileFeature.State {
        var state = ProfileFeature.State()
        state.profile.load = load
        return state
    }

    private func makeStore(
        state: ProfileFeature.State = ProfileFeature.State(),
        fetchMemberProfile: UserInfoUseCaseProfileMock = UserInfoUseCaseProfileMock(),
    ) -> TestStoreOf<ProfileFeature> {
        TestStore(initialState: state) {
            ProfileFeature(profile: fetchMemberProfile.profile)
        }
    }

}
