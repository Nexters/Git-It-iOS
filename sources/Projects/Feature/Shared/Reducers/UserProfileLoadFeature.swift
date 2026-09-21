import ComposableArchitecture
import DomainUserInfo

@Reducer
public struct UserProfileLoadFeature: Sendable {

    // MARK: Lifecycle

    public init(profile: @escaping @Sendable () async throws -> UserProfile) {
        self.profile = profile
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(load: Load = .idle) {
            self.load = load
        }

        // MARK: Public

        public enum Load: Equatable, Sendable {
            case idle
            case loading
            case loaded(UserProfile)
            case failed(UserInfoError)
        }

        public var load: Load
        public var requestID = 0

        public var profile: UserProfile? {
            guard case .loaded(let profile) = load else { return nil }
            return profile
        }

    }

    public enum Action: Equatable, Sendable {
        case input(Input)
        case effect(EffectEvent)

        // MARK: Public

        @CasePathable
        public enum Input: Equatable, Sendable {
            case load
            case reload
            case replace(UserProfile)
        }

        @CasePathable
        public enum EffectEvent: Equatable, Sendable {
            case profileLoadFinished(requestID: Int, result: Result<UserProfile, UserInfoError>)
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .input(.load):
                return startLoad(state: &state, showsLoading: true)

            case .input(.reload):
                switch state.load {
                case .loaded:
                    return startLoad(state: &state, showsLoading: false)

                case .loading:
                    return .none

                case .idle,
                     .failed:
                    return startLoad(state: &state, showsLoading: true)
                }

            case .input(.replace(let profile)):
                state.requestID += 1
                state.load = .loaded(profile)
                return .cancel(id: CancelID.profile)

            case .effect(.profileLoadFinished(let requestID, let result)):
                guard requestID == state.requestID else { return .none }
                switch result {
                case .success(let profile):
                    state.load = .loaded(profile)

                case .failure(let error):
                    if case .loaded = state.load {
                        return .none
                    }
                    state.load = .failed(error)
                }
                return .none
            }
        }
    }

    // MARK: Private

    private enum CancelID {
        case profile
    }

    private let profile: @Sendable () async throws -> UserProfile

    private func startLoad(
        state: inout State,
        showsLoading: Bool,
    ) -> ComposableArchitecture.Effect<Action> {
        state.requestID += 1
        if showsLoading {
            state.load = .loading
        }
        let requestID = state.requestID
        let profile = profile

        return .run { send in
            do {
                await send(.effect(.profileLoadFinished(requestID: requestID, result: .success(try await profile()))))
            } catch let error as UserInfoError {
                await send(.effect(.profileLoadFinished(requestID: requestID, result: .failure(error))))
            } catch {
                await send(.effect(.profileLoadFinished(requestID: requestID, result: .failure(.temporarilyUnavailable))))
            }
        }
        .cancellable(id: CancelID.profile, cancelInFlight: true)
    }

}
