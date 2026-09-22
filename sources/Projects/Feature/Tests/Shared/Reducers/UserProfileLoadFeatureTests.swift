import ComposableArchitecture
import DomainUserInfo
import Foundation
import Testing

@testable import Feature

@MainActor
@Suite("UserProfileLoadFeature 프로필 조회")
struct UserProfileLoadFeatureTests {

    // MARK: Internal

    @Test
    func `load는 로딩을 세우고 받은 프로필로 조회 완료 상태가 된다`() async {
        let profile = profile
        let store = makeStore(profile: { profile })

        await store.send(.input(.load)) {
            $0.load = .loading
            $0.requestID = 1
        }
        await store.receive(.effect(.profileLoadFinished(
            requestID: 1,
            result: .success(profile),
        ))) {
            $0.load = .loaded(profile)
        }

        #expect(store.state.profile == profile)
    }

    @Test
    func `load 실패는 실패 상태를 남긴다`() async {
        let store = makeStore(profile: { throw UserInfoError.temporarilyUnavailable })

        await store.send(.input(.load)) {
            $0.load = .loading
            $0.requestID = 1
        }
        await store.receive(.effect(.profileLoadFinished(
            requestID: 1,
            result: .failure(.temporarilyUnavailable),
        ))) {
            $0.load = .failed(.temporarilyUnavailable)
        }

        #expect(store.state.profile == nil)
    }

    @Test
    func `UserInfoError가 아닌 오류는 일시적 사용 불가로 바꾼다`() async {
        let store = makeStore(profile: { throw URLError(.badServerResponse) })

        await store.send(.input(.load)) {
            $0.load = .loading
            $0.requestID = 1
        }
        await store.receive(.effect(.profileLoadFinished(
            requestID: 1,
            result: .failure(.temporarilyUnavailable),
        ))) {
            $0.load = .failed(.temporarilyUnavailable)
        }
    }

    @Test
    func `조회 완료 상태의 reload는 로딩 없이 최신 프로필로 바꾼다`() async {
        let updatedProfile = updatedProfile
        let store = makeStore(
            state: UserProfileLoadFeature.State(load: .loaded(profile)),
            profile: { updatedProfile },
        )

        await store.send(.input(.reload)) {
            $0.requestID = 1
        }
        await store.receive(.effect(.profileLoadFinished(
            requestID: 1,
            result: .success(updatedProfile),
        ))) {
            $0.load = .loaded(updatedProfile)
        }
    }

    @Test
    func `조회 완료 상태의 reload 실패는 보여 주던 프로필을 유지한다`() async {
        let store = makeStore(
            state: UserProfileLoadFeature.State(load: .loaded(profile)),
            profile: { throw UserInfoError.temporarilyUnavailable },
        )

        await store.send(.input(.reload)) {
            $0.requestID = 1
        }
        await store.receive(.effect(.profileLoadFinished(
            requestID: 1,
            result: .failure(.temporarilyUnavailable),
        )))

        #expect(store.state.load == .loaded(profile))
    }

    @Test
    func `조회 중의 reload는 조회를 새로 시작하지 않는다`() async {
        let profile = profile
        let callCount = LockIsolated(0)
        var state = UserProfileLoadFeature.State(load: .loading)
        state.requestID = 1
        let store = makeStore(
            state: state,
            profile: {
                callCount.withValue { $0 += 1 }
                return profile
            },
        )

        await store.send(.input(.reload))

        #expect(callCount.value == 0)
    }

    @Test(arguments: [
        UserProfileLoadFeature.State.Load.idle,
        .failed(.temporarilyUnavailable),
    ])
    func `조회 완료가 아닌 상태의 reload는 load와 같이 로딩을 세운다`(load: UserProfileLoadFeature.State.Load) async {
        let profile = profile
        let store = makeStore(
            state: UserProfileLoadFeature.State(load: load),
            profile: { profile },
        )

        await store.send(.input(.reload)) {
            $0.load = .loading
            $0.requestID = 1
        }
        await store.receive(.effect(.profileLoadFinished(
            requestID: 1,
            result: .success(profile),
        ))) {
            $0.load = .loaded(profile)
        }
    }

    @Test
    func `replace는 조회 완료 상태로 바꾸고 진행 중인 조회 결과를 무효화한다`() async {
        var state = UserProfileLoadFeature.State(load: .loading)
        state.requestID = 1
        let store = makeStore(state: state)

        await store.send(.input(.replace(updatedProfile))) {
            $0.load = .loaded(updatedProfile)
            $0.requestID = 2
        }
        await store.send(.effect(.profileLoadFinished(
            requestID: 1,
            result: .success(profile),
        )))

        #expect(store.state.load == .loaded(updatedProfile))
    }

    @Test
    func `현재 request ID와 다른 응답은 상태를 바꾸지 않는다`() async {
        var state = UserProfileLoadFeature.State(load: .loading)
        state.requestID = 2
        let store = makeStore(state: state)

        await store.send(.effect(.profileLoadFinished(
            requestID: 1,
            result: .success(profile),
        )))

        #expect(store.state.load == .loading)
    }

    // MARK: Private

    private let profile = SettingsTestFixture.curatedProfile
    private let updatedProfile = SettingsTestFixture.profile(
        position: .ios,
        careerLevel: .senior,
    )

    private func makeStore(
        state: UserProfileLoadFeature.State = UserProfileLoadFeature.State(),
        profile: @escaping @Sendable () async throws -> UserProfile = { throw UserInfoError.temporarilyUnavailable },
    ) -> TestStoreOf<UserProfileLoadFeature> {
        TestStore(initialState: state) {
            UserProfileLoadFeature(profile: profile)
        }
    }

}
