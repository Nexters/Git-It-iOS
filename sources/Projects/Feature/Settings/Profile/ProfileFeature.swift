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

        public var profile = UserProfileLoadFeature.State()

    }

    public enum Action: ViewAction, Equatable, Sendable {
        case view(View)
        case delegate(Delegate)
        case profile(UserProfileLoadFeature.Action)

        // MARK: Public

        @CasePathable
        public enum View: Equatable, Sendable {
            case task
            case retryTapped
            case settingsTapped
        }

        @CasePathable
        public enum Delegate: Equatable, Sendable {
            case settingsRequested
        }
    }

    public var body: some ReducerOf<Self> {
        Scope(state: \.profile, action: \.profile) {
            UserProfileLoadFeature(profile: profile)
        }
        Reduce { state, action in
            switch action {
            case .view(.task):
                switch state.profile.load {
                case .idle,
                     .failed:
                    return .send(.profile(.input(.load)))

                case .loaded:
                    return .send(.profile(.input(.reload)))

                case .loading:
                    return .none
                }

            case .view(.retryTapped):
                guard case .failed = state.profile.load else { return .none }
                return .send(.profile(.input(.load)))

            case .view(.settingsTapped):
                return .send(.delegate(.settingsRequested))

            case .profile,
                 .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private let profile: @Sendable () async throws -> UserProfile

}
