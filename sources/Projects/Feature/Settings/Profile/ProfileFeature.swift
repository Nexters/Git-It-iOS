import ComposableArchitecture
import DomainUserInfo

@Reducer
public struct ProfileFeature: Sendable {

    // MARK: Lifecycle

    public init(profile: @escaping @Sendable () async throws -> UserProfile) {
        self.profile = profile
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init() { }

        // MARK: Public

        public enum ProfileLoad: Equatable, Sendable {
            case idle
            case loading
            case loaded(UserProfile)
            case failed(UserInfoError)
        }

        public var profileLoad = ProfileLoad.idle
        public var profileRequestID = 0

    }

    public enum Action: ViewAction, Equatable, Sendable {
        case view(View)
        case effect(EffectEvent)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum View: Equatable, Sendable {
            case task
            case retryTapped
            case settingsTapped
        }

        @CasePathable
        public enum EffectEvent: Equatable, Sendable {
            case profileLoadFinished(requestID: Int, result: Result<UserProfile, UserInfoError>)
        }

        @CasePathable
        public enum Delegate: Equatable, Sendable {
            case settingsRequested
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.task):
                switch state.profileLoad {
                case .idle,
                     .failed:
                    return startProfileLoad(state: &state, showsLoading: true)

                case .loaded:
                    return startProfileLoad(state: &state, showsLoading: false)

                case .loading:
                    return .none
                }

            case .view(.retryTapped):
                guard case .failed = state.profileLoad else { return .none }
                return startProfileLoad(state: &state, showsLoading: true)

            case .view(.settingsTapped):
                return .send(.delegate(.settingsRequested))

            case .effect(.profileLoadFinished(let requestID, let result)):
                guard requestID == state.profileRequestID else { return .none }
                switch result {
                case .success(let profile):
                    state.profileLoad = .loaded(profile)

                case .failure(let error):
                    if case .loaded = state.profileLoad {
                        return .none
                    }
                    state.profileLoad = .failed(error)
                }
                return .none

            case .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private enum CancelID {
        case profile
    }

    private let profile: @Sendable () async throws -> UserProfile

    private func startProfileLoad(
        state: inout State,
        showsLoading: Bool,
    ) -> ComposableArchitecture.Effect<Action> {
        state.profileRequestID += 1
        if showsLoading {
            state.profileLoad = .loading
        }
        let requestID = state.profileRequestID
        let profile = profile

        return .run { send in
            do {
                await send(.effect(.profileLoadFinished(
                    requestID: requestID,
                    result: .success(try await profile()),
                )))
            } catch let error as UserInfoError {
                await send(.effect(.profileLoadFinished(requestID: requestID, result: .failure(error))))
            } catch {
                await send(.effect(.profileLoadFinished(
                    requestID: requestID,
                    result: .failure(.temporarilyUnavailable),
                )))
            }
        }
        .cancellable(id: CancelID.profile, cancelInFlight: true)
    }

}
