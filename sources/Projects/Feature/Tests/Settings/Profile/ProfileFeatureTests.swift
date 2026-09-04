import ComposableArchitecture
import Testing

@testable import Feature

@MainActor
@Suite("ProfileFeature 프로필 조회")
struct ProfileFeatureTests {

    // MARK: Internal

    @Test
    func `최초 task는 로딩을 세우고 받은 프로필을 노출한다`() async {
        let fetchMemberProfile = FetchMemberProfileUseCaseMock(results: [.success(SettingsTestFixture.curatedProfile)])
        let store = makeStore(fetchMemberProfile: fetchMemberProfile)

        await store.send(.view(.task)) {
            $0.profileLoad = .loading
            $0.profileRequestID = 1
        }
        await store.receive(.effect(.profileLoadFinished(
            requestID: 1,
            result: .success(SettingsTestFixture.curatedProfile),
        ))) {
            $0.profileLoad = .loaded(SettingsTestFixture.curatedProfile)
        }

        #expect(await fetchMemberProfile.snapshot() == 1)
    }

    @Test
    func `이미 받은 프로필이 있으면 task는 로딩을 거치지 않고 최신 값으로 바꾼다`() async {
        let updated = SettingsTestFixture.profile(position: .ios, careerLevel: .senior)
        let store = makeStore(
            state: makeState(profileLoad: .loaded(SettingsTestFixture.curatedProfile)),
            fetchMemberProfile: FetchMemberProfileUseCaseMock(results: [.success(updated)]),
        )

        await store.send(.view(.task)) {
            $0.profileRequestID = 1
        }
        await store.receive(.effect(.profileLoadFinished(requestID: 1, result: .success(updated)))) {
            $0.profileLoad = .loaded(updated)
        }
    }

    @Test
    func `갱신 실패는 이미 보여 주던 프로필을 그대로 유지한다`() async {
        let store = makeStore(
            state: makeState(profileLoad: .loaded(SettingsTestFixture.curatedProfile)),
            fetchMemberProfile: FetchMemberProfileUseCaseMock(results: [.failure(.temporarilyUnavailable)]),
        )

        await store.send(.view(.task)) {
            $0.profileRequestID = 1
        }
        await store.receive(.effect(.profileLoadFinished(
            requestID: 1,
            result: .failure(.temporarilyUnavailable),
        )))

        #expect(store.state.profileLoad == .loaded(SettingsTestFixture.curatedProfile))
    }

    @Test
    func `최초 조회 실패는 실패 상태를 남기고 재시도로 다시 조회한다`() async {
        let fetchMemberProfile = FetchMemberProfileUseCaseMock(results: [
            .failure(.temporarilyUnavailable),
            .success(SettingsTestFixture.curatedProfile),
        ])
        let store = makeStore(fetchMemberProfile: fetchMemberProfile)

        await store.send(.view(.task)) {
            $0.profileLoad = .loading
            $0.profileRequestID = 1
        }
        await store.receive(.effect(.profileLoadFinished(
            requestID: 1,
            result: .failure(.temporarilyUnavailable),
        ))) {
            $0.profileLoad = .failed(.temporarilyUnavailable)
        }

        await store.send(.view(.retryTapped)) {
            $0.profileLoad = .loading
            $0.profileRequestID = 2
        }
        await store.receive(.effect(.profileLoadFinished(
            requestID: 2,
            result: .success(SettingsTestFixture.curatedProfile),
        ))) {
            $0.profileLoad = .loaded(SettingsTestFixture.curatedProfile)
        }

        #expect(await fetchMemberProfile.snapshot() == 2)
    }

    @Test
    func `실패 상태가 아니면 재시도는 조회하지 않는다`() async {
        let fetchMemberProfile = FetchMemberProfileUseCaseMock(results: [.success(SettingsTestFixture.curatedProfile)])
        let store = makeStore(
            state: makeState(profileLoad: .loaded(SettingsTestFixture.curatedProfile)),
            fetchMemberProfile: fetchMemberProfile,
        )

        await store.send(.view(.retryTapped))

        #expect(await fetchMemberProfile.snapshot() == 0)
    }

    @Test
    func `조회 중인 동안 다시 들어온 task는 조회를 새로 시작하지 않는다`() async {
        let fetchMemberProfile = FetchMemberProfileUseCaseMock(results: [.success(SettingsTestFixture.curatedProfile)])
        var initialState = makeState(profileLoad: .loading)
        initialState.profileRequestID = 1
        let store = makeStore(state: initialState, fetchMemberProfile: fetchMemberProfile)

        await store.send(.view(.task))

        #expect(await fetchMemberProfile.snapshot() == 0)
    }

    @Test
    func `현재 request ID와 다른 응답은 상태를 바꾸지 않는다`() async {
        var initialState = makeState(profileLoad: .loading)
        initialState.profileRequestID = 2
        let store = makeStore(state: initialState)

        await store.send(.effect(.profileLoadFinished(
            requestID: 1,
            result: .success(SettingsTestFixture.curatedProfile),
        )))
    }

    @Test
    func `설정 아이콘 탭은 설정 요청 delegate를 올린다`() async {
        let store = makeStore()

        await store.send(.view(.settingsTapped))
        await store.receive(.delegate(.settingsRequested))
    }

    // MARK: Private

    private func makeState(profileLoad: ProfileFeature.State.ProfileLoad) -> ProfileFeature.State {
        var state = ProfileFeature.State()
        state.profileLoad = profileLoad
        return state
    }

    private func makeStore(
        state: ProfileFeature.State = ProfileFeature.State(),
        fetchMemberProfile: FetchMemberProfileUseCaseMock = FetchMemberProfileUseCaseMock(),
    ) -> TestStoreOf<ProfileFeature> {
        TestStore(initialState: state) {
            ProfileFeature(fetchMemberProfile: fetchMemberProfile)
        }
    }

}
